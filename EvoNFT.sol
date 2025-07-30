// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DynamicNFT
 * @dev Main ERC-721 contract for EvoNFT with dynamic evolution capabilities
 */
contract DynamicNFT is 
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EVOLUTION_ROLE = keccak256("EVOLUTION_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    Counters.Counter private _tokenIdCounter;

    struct NFTData {
        uint256 evolutionStage;
        uint256 utilityScore;
        uint256 lastEvolution;
        uint256 experiencePoints;
        bytes32 personalityHash;
        uint256[] traits;
        mapping(uint256 => uint256) chainStates; // chainId => state
        mapping(address => uint256) interactions; // user => count
    }

    struct EvolutionMetadata {
        string name;
        string description;
        string imageURI;
        string animationURI;
        uint256 rarity;
        string[] attributes;
    }

    mapping(uint256 => NFTData) private _nftData;
    mapping(uint256 => EvolutionMetadata) private _evolutionMetadata;
    mapping(uint256 => bool) public evolutionEnabled;
    
    // Evolution requirements
    mapping(uint256 => uint256) public evolutionTimeRequired; // stage => time in seconds
    mapping(uint256 => uint256) public evolutionXPRequired; // stage => XP required
    
    // Cross-chain compatibility
    mapping(uint256 => bool) public crossChainEnabled; // chainId => enabled
    mapping(uint256 => address) public crossChainContracts; // chainId => contract address

    // Events
    event NFTMinted(uint256 indexed tokenId, address indexed owner, uint256 initialStage);
    event EvolutionTriggered(uint256 indexed tokenId, uint256 fromStage, uint256 toStage);
    event UtilityScoreUpdated(uint256 indexed tokenId, uint256 newScore);
    event CrossChainTransfer(uint256 indexed tokenId, uint256 fromChain, uint256 toChain);
    event InteractionRecorded(uint256 indexed tokenId, address indexed user, string interactionType);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("EvoNFT", "EVONFT");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(EVOLUTION_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    /**
     * @dev Mint a new dynamic NFT
     */
    function mint(
        address to,
        string memory uri,
        uint256[] memory initialTraits,
        bytes32 personalityHash
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
        NFTData storage nftData = _nftData[tokenId];
        nftData.evolutionStage = 1;
        nftData.utilityScore = 0;
        nftData.lastEvolution = block.timestamp;
        nftData.experiencePoints = 0;
        nftData.personalityHash = personalityHash;
        nftData.traits = initialTraits;
        
        evolutionEnabled[tokenId] = true;
        
        emit NFTMinted(tokenId, to, 1);
        return tokenId;
    }

    /**
     * @dev Record interaction with NFT for experience points
     */
    function recordInteraction(
        uint256 tokenId,
        address user,
        string memory interactionType,
        uint256 xpGain
    ) external onlyRole(EVOLUTION_ROLE) {
        require(ownerOf(tokenId), "Token does not exist");
        
        NFTData storage nftData = _nftData[tokenId];
        nftData.interactions[user] += 1;
        nftData.experiencePoints += xpGain;
        
        emit InteractionRecorded(tokenId, user, interactionType);
    }

    /**
     * @dev Update utility score based on cross-platform usage
     */
    function updateUtilityScore(uint256 tokenId, uint256 newScore) 
        external 
        onlyRole(EVOLUTION_ROLE) 
    {
        require(ownerOf(tokenId), "Token does not exist");
        _nftData[tokenId].utilityScore = newScore;
        emit UtilityScoreUpdated(tokenId, newScore);
    }

    /**
     * @dev Trigger evolution if criteria are met
     */
    function triggerEvolution(uint256 tokenId) external onlyRole(EVOLUTION_ROLE) {
        require(ownerOf(tokenId), "Token does not exist");
        require(evolutionEnabled[tokenId], "Evolution disabled for this token");
        
        NFTData storage nftData = _nftData[tokenId];
        uint256 currentStage = nftData.evolutionStage;
        
        // Check evolution criteria
        require(
            block.timestamp >= nftData.lastEvolution + evolutionTimeRequired[currentStage],
            "Time requirement not met"
        );
        require(
            nftData.experiencePoints >= evolutionXPRequired[currentStage],
            "XP requirement not met"
        );
        
        uint256 newStage = currentStage + 1;
        nftData.evolutionStage = newStage;
        nftData.lastEvolution = block.timestamp;
        
        emit EvolutionTriggered(tokenId, currentStage, newStage);
    }

    /**
     * @dev Get NFT data
     */
    function getNFTData(uint256 tokenId) external view returns (
        uint256 evolutionStage,
        uint256 utilityScore,
        uint256 lastEvolution,
        uint256 experiencePoints,
        bytes32 personalityHash,
        uint256[] memory traits
    ) {
        require(ownerOf(tokenId), "Token does not exist");
        NFTData storage nftData = _nftData[tokenId];
        
        return (
            nftData.evolutionStage,
            nftData.utilityScore,
            nftData.lastEvolution,
            nftData.experiencePoints,
            nftData.personalityHash,
            nftData.traits
        );
    }

    /**
     * @dev Check if NFT can evolve
     */
    function canEvolve(uint256 tokenId) external view returns (bool) {
        if (!ownerOf(tokenId) || !evolutionEnabled[tokenId]) return false;
        
        NFTData storage nftData = _nftData[tokenId];
        uint256 currentStage = nftData.evolutionStage;
        
        bool timeReq = block.timestamp >= nftData.lastEvolution + evolutionTimeRequired[currentStage];
        bool xpReq = nftData.experiencePoints >= evolutionXPRequired[currentStage];
        
        return timeReq && xpReq;
    }

    // Administrative functions
    function setEvolutionRequirements(
        uint256 stage,
        uint256 timeRequired,
        uint256 xpRequired
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        evolutionTimeRequired[stage] = timeRequired;
        evolutionXPRequired[stage] = xpRequired;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // Required overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/**
 * @title EvolutionEngine
 * @dev Handles NFT evolution logic with Chainlink VRF for randomness
 */
contract EvolutionEngine is VRFConsumerBaseV2, AccessControlUpgradeable, PausableUpgradeable {
    VRFCoordinatorV2Interface COORDINATOR;
    
    bytes32 public constant EVOLUTION_MANAGER_ROLE = keccak256("EVOLUTION_MANAGER_ROLE");
    
    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;
    
    DynamicNFT public dynamicNFT;
    AIPersonality public aiPersonality;
    
    struct EvolutionRequest {
        uint256 tokenId;
        address owner;
        uint256 currentStage;
        bool fulfilled;
    }
    
    mapping(uint256 => EvolutionRequest) public evolutionRequests;
    mapping(uint256 => uint256[]) public evolutionPaths; // stage => possible next stages
    
    // Oracle data feeds
    AggregatorV3Interface internal priceFeed;
    mapping(string => AggregatorV3Interface) public dataFeeds; // "weather", "sentiment", etc.
    
    event EvolutionRequested(uint256 indexed requestId, uint256 indexed tokenId);
    event EvolutionCompleted(uint256 indexed tokenId, uint256 newStage, uint256[] newTraits);
    event OracleDataUpdated(string indexed dataType, int256 value);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EVOLUTION_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Request evolution for an NFT
     */
    function requestEvolution(uint256 tokenId) external returns (uint256 requestId) {
        require(dynamicNFT.canEvolve(tokenId), "NFT cannot evolve yet");
        
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        
        (uint256 evolutionStage,,,,,) = dynamicNFT.getNFTData(tokenId);
        
        evolutionRequests[requestId] = EvolutionRequest({
            tokenId: tokenId,
            owner: msg.sender,
            currentStage: evolutionStage,
            fulfilled: false
        });
        
        emit EvolutionRequested(requestId, tokenId);
        return requestId;
    }

    /**
     * @dev Chainlink VRF callback
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        EvolutionRequest storage request = evolutionRequests[requestId];
        require(!request.fulfilled, "Request already fulfilled");
        
        request.fulfilled = true;
        
        // Process evolution with randomness
        _processEvolution(request.tokenId, request.currentStage, randomWords);
    }

    /**
     * @dev Process evolution with random traits
     */
    function _processEvolution(
        uint256 tokenId,
        uint256 currentStage,
        uint256[] memory randomWords
    ) internal {
        // Determine next evolution stage
        uint256[] memory possibleStages = evolutionPaths[currentStage];
        require(possibleStages.length > 0, "No evolution path available");
        
        uint256 nextStage = possibleStages[randomWords[0] % possibleStages.length];
        
        // Generate new traits based on randomness and external data
        uint256[] memory newTraits = _generateTraits(tokenId, nextStage, randomWords[1]);
        
        // Update NFT
        dynamicNFT.triggerEvolution(tokenId);
        
        // Update AI personality
        aiPersonality.evolvePersonality(tokenId, nextStage, newTraits);
        
        emit EvolutionCompleted(tokenId, nextStage, newTraits);
    }

    /**
     * @dev Generate new traits based on randomness and external factors
     */
    function _generateTraits(
        uint256 tokenId,
        uint256 stage,
        uint256 randomness
    ) internal view returns (uint256[] memory) {
        uint256[] memory traits = new uint256[](5);
        
        // Base traits from randomness
        traits[0] = (randomness % 100) + 1; // Strength
        traits[1] = ((randomness >> 8) % 100) + 1; // Intelligence
        traits[2] = ((randomness >> 16) % 100) + 1; // Agility
        traits[3] = ((randomness >> 24) % 100) + 1; // Charisma
        
        // Environmental factor (weather influence)
        int256 weatherData = _getLatestPrice("weather");
        if (weatherData > 0) {
            traits[4] = uint256(weatherData % 100) + 1; // Weather affinity
        } else {
            traits[4] = 50; // Neutral
        }
        
        return traits;
    }

    /**
     * @dev Get latest price from oracle
     */
    function _getLatestPrice(string memory dataType) internal view returns (int256) {
        AggregatorV3Interface feed = dataFeeds[dataType];
        if (address(feed) == address(0)) return 0;
        
        (, int256 price, , ,) = feed.latestRoundData();
        return price;
    }

    /**
     * @dev Set evolution paths for each stage
     */
    function setEvolutionPath(uint256 stage, uint256[] memory nextStages) 
        external 
        onlyRole(EVOLUTION_MANAGER_ROLE) 
    {
        evolutionPaths[stage] = nextStages;
    }

    /**
     * @dev Add data feed for external data
     */
    function addDataFeed(string memory dataType, address feedAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        dataFeeds[dataType] = AggregatorV3Interface(feedAddress);
    }

    /**
     * @dev Set contracts
     */
    function setContracts(address _dynamicNFT, address _aiPersonality) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        dynamicNFT = DynamicNFT(_dynamicNFT);
        aiPersonality = AIPersonality(_aiPersonality);
    }
}

/**
 * @title AIPersonality
 * @dev Manages AI personality traits and learning for NFTs
 */
contract AIPersonality is AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public constant PERSONALITY_MANAGER_ROLE = keccak256("PERSONALITY_MANAGER_ROLE");
    
    struct PersonalityData {
        uint256[] traits; // [curiosity, creativity, empathy, logic, humor]
        uint256 learningRate;
        uint256 experienceLevel;
        mapping(string => uint256) interactions; // interaction type => count
        mapping(address => uint256) socialConnections; // user => relationship strength
        string[] memories; // stored conversation highlights
    }
    
    mapping(uint256 => PersonalityData) private personalities;
    mapping(uint256 => mapping(string => uint256)) public skillLevels; // tokenId => skill => level
    
    // Personality evolution rules
    mapping(uint256 => uint256) public personalityEvolutionThresholds; // stage => required interactions
    
    event PersonalityEvolved(uint256 indexed tokenId, uint256[] newTraits);
    event InteractionLearned(uint256 indexed tokenId, string interactionType, uint256 skillGain);
    event SocialConnectionFormed(uint256 indexed tokenId, address indexed user, uint256 strength);
    event MemoryStored(uint256 indexed tokenId, string memoryData);

    function initialize() initializer public {
        __AccessControl_init();
        __Pausable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PERSONALITY_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Initialize personality for new NFT
     */
    function initializePersonality(
        uint256 tokenId,
        uint256[] memory initialTraits,
        uint256 learningRate
    ) external onlyRole(PERSONALITY_MANAGER_ROLE) {
        PersonalityData storage personality = personalities[tokenId];
        personality.traits = initialTraits;
        personality.learningRate = learningRate;
        personality.experienceLevel = 0;
    }

    /**
     * @dev Record interaction and update personality
     */
    function recordInteraction(
        uint256 tokenId,
        string memory interactionType,
        address user,
        uint256 intensity
    ) external onlyRole(PERSONALITY_MANAGER_ROLE) {
        PersonalityData storage personality = personalities[tokenId];
        
        // Update interaction count
        personality.interactions[interactionType] += 1;
        
        // Update social connection
        personality.socialConnections[user] += intensity;
        
        // Learn from interaction
        uint256 skillGain = (intensity * personality.learningRate) / 100;
        skillLevels[tokenId][interactionType] += skillGain;
        
        // Update experience
        personality.experienceLevel += intensity;
        
        emit InteractionLearned(tokenId, interactionType, skillGain);
        emit SocialConnectionFormed(tokenId, user, personality.socialConnections[user]);
        
        // Check if personality should evolve
        _checkPersonalityEvolution(tokenId);
    }

    /**
     * @dev Evolve personality based on evolution stage
     */
    function evolvePersonality(
        uint256 tokenId,
        uint256 newStage,
        uint256[] memory evolutionBonus
    ) external onlyRole(PERSONALITY_MANAGER_ROLE) {
        PersonalityData storage personality = personalities[tokenId];
        
        // Apply evolution bonus to traits
        for (uint i = 0; i < personality.traits.length && i < evolutionBonus.length; i++) {
            personality.traits[i] += evolutionBonus[i];
            if (personality.traits[i] > 100) personality.traits[i] = 100;
        }
        
        // Increase learning rate with evolution
        personality.learningRate += 5;
        if (personality.learningRate > 50) personality.learningRate = 50;
        
        emit PersonalityEvolved(tokenId, personality.traits);
    }

    /**
     * @dev Store memory from conversation
     */
    function storeMemory(uint256 tokenId, string memory memoryData) 
        external 
        onlyRole(PERSONALITY_MANAGER_ROLE) 
    {
        personalities[tokenId].memories.push(memoryData);
        emit MemoryStored(tokenId, memoryData);
    }

    /**
     * @dev Get personality data
     */
    function getPersonalityData(uint256 tokenId) external view returns (
        uint256[] memory traits,
        uint256 learningRate,
        uint256 experienceLevel,
        string[] memory memories
    ) {
        PersonalityData storage personality = personalities[tokenId];
        return (
            personality.traits,
            personality.learningRate,
            personality.experienceLevel,
            personality.memories
        );
    }

    /**
     * @dev Get social connection strength
     */
    function getSocialConnection(uint256 tokenId, address user) 
        external 
        view 
        returns (uint256) 
    {
        return personalities[tokenId].socialConnections[user];
    }

    /**
     * @dev Check if personality should evolve
     */
    function _checkPersonalityEvolution(uint256 tokenId) internal {
        PersonalityData storage personality = personalities[tokenId];
        
        // Simple evolution trigger based on experience
        if (personality.experienceLevel >= 1000 && personality.learningRate < 50) {
            personality.learningRate += 1;
            personality.experienceLevel = 0; // Reset for next evolution
        }
    }

    /**
     * @dev Set personality evolution thresholds
     */
    function setPersonalityEvolutionThreshold(uint256 stage, uint256 threshold) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        personalityEvolutionThresholds[stage] = threshold;
    }
}

/**
 * @title UtilityStaking
 * @dev Multi-tier staking system with dynamic APY based on utility scores
 */
contract UtilityStaking is AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    
    bytes32 public constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");
    
    DynamicNFT public dynamicNFT;
    IERC20 public rewardToken;
    
    struct StakingPool {
        uint256 baseAPY; // Base APY in basis points (10000 = 100%)
        uint256 utilityMultiplier; // Multiplier based on utility score
        uint256 totalStaked;
        uint256 totalRewards;
        bool active;
    }
    
    struct StakingPosition {
        uint256 tokenId;
        uint256 poolId;
        uint256 stakedAt;
        uint256 lastClaimAt;
        uint256 accumulatedRewards;
    }
    
    mapping(uint256 => StakingPool) public stakingPools;
    mapping(uint256 => StakingPosition) public stakingPositions; // tokenId => position
    mapping(address => uint256[]) public userStakedTokens;
    
    uint256 public poolCount;
    uint256 public constant MAX_UTILITY_MULTIPLIER = 300; // 3x max multiplier
    
    event TokenStaked(uint256 indexed tokenId, uint256 indexed poolId, address indexed owner);
    event TokenUnstaked(uint256 indexed tokenId, address indexed owner, uint256 rewards);
    event RewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event PoolCreated(uint256 indexed poolId, uint256 baseAPY, uint256 utilityMultiplier);

    function initialize(address _dynamicNFT, address _rewardToken) initializer public {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        
        dynamicNFT = DynamicNFT(_dynamicNFT);
        rewardToken = IERC20(_rewardToken);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(STAKING_MANAGER_ROLE, msg.sender);
    }

    /**
     * @dev Create new staking pool
     */
    function createPool(
        uint256 baseAPY,
        uint256 utilityMultiplier
    ) external onlyRole(STAKING_MANAGER_ROLE) returns (uint256) {
        uint256 poolId = poolCount++;
        
        stakingPools[poolId] = StakingPool({
            baseAPY: baseAPY,
            utilityMultiplier: utilityMultiplier,
            totalStaked: 0,
            totalRewards: 0,
            active: true
        });
        
        emit PoolCreated(poolId, baseAPY, utilityMultiplier);
        return poolId;
    }

    /**
     * @dev Stake NFT in pool
     */
    function stake(uint256 tokenId, uint256 poolId) external nonReentrant whenNotPaused {
        require(dynamicNFT.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(stakingPools[poolId].active, "Pool not active");
        require(stakingPositions[tokenId].tokenId == 0, "Token already staked");
        
        dynamicNFT.transferFrom(msg.sender, address(this), tokenId);
        
        stakingPositions[tokenId] = StakingPosition({
            tokenId: tokenId,
            poolId: poolId,
            stakedAt: block.timestamp,
            lastClaimAt: block.timestamp,
            accumulatedRewards: 0
        });
        
        stakingPools[poolId].totalStaked++;
        userStakedTokens[msg.sender].push(tokenId);
        
        emit TokenStaked(tokenId, poolId, msg.sender);
    }

    /**
     * @dev Unstake NFT and claim rewards
     */
    function unstake(uint256 tokenId) external nonReentrant {
        StakingPosition storage position = stakingPositions[tokenId];
        require(position.tokenId != 0, "Token not staked");
        
        // Calculate and transfer rewards
        uint256 rewards = calculateRewards(tokenId);
        if (rewards > 0) {
            rewardToken.transfer(msg.sender, rewards);
        }
        
        // Return NFT
        dynamicNFT.transferFrom(address(this), msg.sender, tokenId);
        
        // Update pool
        stakingPools[position.poolId].totalStaked--;
        
        // Remove from user's staked tokens
        function _removeUserStakedToken(address user, uint256 tokenId) internal {
    uint256[] storage tokens = userStakedTokens[user];
    for (uint256 i = 0; i < tokens.length; i++) {
        if (tokens[i] == tokenId) {
            // Option 1: Swap with last element and pop (order doesn’t matter)
            tokens[i] = tokens[tokens.length - 1];
            tokens.pop();
            break;
        }
    }
}

        
        // Clear position
        delete stakingPositions[tokenId];
        
        emit TokenUnstaked(tokenId, msg.sender, rewards);
    }

    /**
     * @dev Claim rewards without unstaking
     */
    function claimRewards(uint256 tokenId) external nonReentrant {
        StakingPosition storage position = stakingPositions[tokenId];
        require(position.tokenId != 0, "Token not staked");
        
        uint256 rewards = calculateRewards(tokenId);
        require(rewards > 0, "No rewards available");
        
        position.lastClaimAt = block.timestamp;
        position.accumulatedRewards = 0;
        
        rewardToken.transfer(msg.sender, rewards);
        
        emit RewardsClaimed(tokenId, msg.sender, rewards);
    }

    /**
     * @dev Calculate rewards for staked NFT
     */
    function calculateRewards(uint256 tokenId) public view returns (uint256) {
        StakingPosition storage position = stakingPositions[tokenId];
        if (position.tokenId == 0) return 0;
        
        StakingPool storage pool = stakingPools[position.poolId];
        
        // Get NFT utility score
        (, uint256 utilityScore, , , ,) = dynamicNFT.getNFTData(tokenId);
        
        // Calculate time staked
        uint256 timeStaked = block.timestamp.sub(position.lastClaimAt);
        
        // Calculate base rewards
        uint256 baseRewards = timeStaked.mul(pool.baseAPY).div(365 days).div(10000);
        
        // Apply utility multiplier
        uint256 utilityMultiplier = utilityScore.mul(pool.utilityMultiplier).div(100);
        if (utilityMultiplier > MAX_UTILITY_MULTIPLIER) {
            utilityMultiplier = MAX_UTILITY_MULTIPLIER;
        }
        
        uint256 totalRewards = baseRewards.mul(100 + utilityMultiplier).div(100);
        
        return totalRewards.add(position.accumulatedRewards);
    }

    /**
     * @dev Get user's staked tokens
     */
    function getUserStakedTokens(address user) external view returns (uint256[] memory) {
        return userStakedTokens[user];
    } }
