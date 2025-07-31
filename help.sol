// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ProofOfHelp is Ownable {
    /// @notice Struct to record help actions
    struct HelpRecord {
        address helper;
        address recipient;
        string message;
        string category;  // e.g., "food", "education", etc.
        string location;  // e.g., "Lagos, Nigeria"
        uint256 timestamp;
    }

    HelpRecord[] public allHelpRecords;

    /// @notice Track how many times an address helped others
    mapping(address => uint256) public reputation;

    /// @notice Track when a user last helped (for frequency limit)
    mapping(address => uint256) public lastHelpTime;

    /// @notice Track records for each helper
    mapping(address => HelpRecord[]) private userHelpRecords;

    /// @notice Event emitted when someone gives help
    event HelpGiven(
        address indexed helper,
        address indexed recipient,
        string message,
        string category,
        string location,
        uint256 timestamp
    );

    /// @notice Event for penalizing users
    event ReputationPenalized(address indexed user, uint256 amount);

    /// @notice Prevent self-help and enforce 1-help-per-day
    function giveHelp(
        address _recipient,
        string memory _message,
        string memory _category,
        string memory _location
    ) external {
        require(msg.sender != _recipient, "Cannot help yourself");
        require(_recipient != address(0), "Invalid recipient address");
        require(
            block.timestamp - lastHelpTime[msg.sender] >= 1 days,
            "Can only help once every 24 hours"
        );

        HelpRecord memory record = HelpRecord({
            helper: msg.sender,
            recipient: _recipient,
            message: _message,
            category: _category,
            location: _location,
            timestamp: block.timestamp
        });

        allHelpRecords.push(record);
        userHelpRecords[msg.sender].push(record);

        reputation[msg.sender] += 1;
        lastHelpTime[msg.sender] = block.timestamp;

        emit HelpGiven(
            msg.sender,
            _recipient,
            _message,
            _category,
            _location,
            block.timestamp
        );
    }

    /// @notice Public view of all help records
    function getAllRecords() external view returns (HelpRecord[] memory) {
        return allHelpRecords;
    }

    /// @notice View reputation score of any address
    function getReputation(address _user) external view returns (uint256) {
        return reputation[_user];
    }

    /// @notice Total number of help records
    function getHelpCount() external view returns (uint256) {
        return allHelpRecords.length;
    }

    /// @notice Get help history for a specific helper
    function getRecordsByHelper(address _helper) external view returns (HelpRecord[] memory) {
        return userHelpRecords[_helper];
    }

    /// @notice Penalize a user by reducing reputation (owner only)
    function penalizeReputation(address _user, uint256 _amount) external onlyOwner {
        if (reputation[_user] < _amount) {
            reputation[_user] = 0;
        } else {
            reputation[_user] -= _amount;
        }
        emit ReputationPenalized(_user, _amount);
    }

    /// @notice Reset all records and reputations (owner only)
    function resetSystem() external onlyOwner {
        delete allHelpRecords;

        // Reset mappings (brute force for demonstration; not gas efficient on-chain)
        // In a real production contract, you’d consider indexing helpers separately
        for (uint i = 0; i < allHelpRecords.length; i++) {
            address helper = allHelpRecords[i].helper;
            delete reputation[helper];
            delete userHelpRecords[helper];
            delete last
