# EvoNFT - Dynamic NFT Marketplace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.19-blue.svg)](https://soliditylang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-green.svg)](https://nodejs.org/)
[![Next.js](https://img.shields.io/badge/Next.js-14.x-black.svg)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg)](https://www.typescriptlang.org/)

> **Revolutionary Dynamic NFT Marketplace where digital assets evolve, learn, and provide genuine utility across multiple platforms.**

EvoNFT is not just another NFT marketplace—it's a comprehensive ecosystem that transforms static digital assets into living, evolving companions with AI personalities, cross-chain compatibility, and real-world utility integration.

## 🌟 Key Features

- **Dynamic Evolution**: NFTs that transform based on time, usage, and real-world data
- **AI Personalities**: Each NFT develops unique AI traits that learn from interactions
- **Cross-Chain Native**: Seamless functionality across Ethereum, Polygon, Arbitrum, and Solana
- **Gaming Integration**: Native SDKs for Unity, Unreal Engine, and web-based games
- **Utility Staking**: Earn rewards based on NFT utility scores and cross-platform usage
- **Real-World Data**: Weather, market conditions, and social sentiment influence NFT evolution

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │  Smart Contracts│
│   (Next.js)     │◄──►│   (Node.js)     │◄──►│   (Solidity)    │
│                 │    │                 │    │                 │
│ • 3D Viewer     │    │ • GraphQL API   │    │ • DynamicNFT    │
│ • Evolution UI  │    │ • WebSocket     │    │ • EvolutionEngine│
│ • AI Chat       │    │ • Oracle Bridge │    │ • AIPersonality │
│ • Portfolio     │    │ • Analytics     │    │ • UtilityStaking│
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │              ┌─────────────────┐              │
        │              │  External APIs  │              │
        └──────────────►│                 │◄─────────────┘
                       │ • Chainlink     │
                       │ • IPFS          │
                       │ • Weather APIs  │
                       │ • Social APIs   │
                       └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18.x or higher
- Hardhat or Foundry for smart contract development
- MetaMask or compatible Web3 wallet
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/evonft/evonft-marketplace.git
cd evonft-marketplace

# Install dependencies
npm install

# Install smart contract dependencies
cd contracts
npm install
cd ..

# Install frontend dependencies
cd frontend
npm install
cd ..

# Install backend dependencies
cd backend
npm install
cd ..
```

### Environment Setup

Create `.env` files in each directory:

**Root `.env`:**
```env
# Network Configuration
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
POLYGON_RPC_URL=https://polygon-mainnet.infura.io/v3/YOUR_KEY
ARBITRUM_RPC_URL=https://arbitrum-mainnet.infura.io/v3/YOUR_KEY

# Private Keys (use test keys for development)
DEPLOYER_PRIVATE_KEY=your_private_key_here
OWNER_PRIVATE_KEY=your_private_key_here

# Chainlink Configuration
CHAINLINK_VRF_COORDINATOR=0x271682DEB8C4E0901D1a1550aD2e64D568E69909
CHAINLINK_KEY_HASH=0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
```

**Backend `.env`:**
```env
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/evonft
MONGODB_URL=mongodb://localhost:27017/evonft
REDIS_URL=redis://localhost:6379

# API Keys
WEATHER_API_KEY=your_weather_api_key
SOCIAL_API_KEY=your_social_api_key
IPFS_PROJECT_ID=your_ipfs_project_id
IPFS_PROJECT_SECRET=your_ipfs_secret

# JWT
JWT_SECRET=your_jwt_secret_here
```

**Frontend `.env.local`:**
```env
NEXT_PUBLIC_CONTRACT_ADDRESS=0x...
NEXT_PUBLIC_CHAIN_ID=1
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_IPFS_GATEWAY=https://ipfs.io/ipfs/
```

### Development Setup

1. **Start Local Blockchain:**
```bash
# Using Hardhat
npx hardhat node

# Or using Ganache
ganache-cli --deterministic --accounts 10 --host 0.0.0.0
```

2. **Deploy Smart Contracts:**
```bash
cd contracts
npm run compile
npm run deploy:local
```

3. **Start Backend Services:**
```bash
cd backend
npm run dev
```

4. **Start Frontend Development Server:**
```bash
cd frontend
npm run dev
```

Visit `http://localhost:3000` to access the application.

## 📁 Project Structure

```
evonft-marketplace/
├── contracts/                 # Smart contracts
│   ├── src/
│   │   ├── DynamicNFT.sol
│   │   ├── EvolutionEngine.sol
│   │   ├── AIPersonality.sol
│   │   ├── UtilityStaking.sol
│   │   ├── CrossChainBridge.sol
│   │   └── MarketplaceCore.sol
│   ├── test/                  # Contract tests
│   ├── scripts/               # Deployment scripts
│   └── hardhat.config.js
├── backend/                   # Node.js API server
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   ├── middleware/
│   │   └── utils/
│   ├── prisma/                # Database schema
│   └── package.json
├── frontend/                  # Next.js application
│   ├── components/
│   │   ├── 3d/               # Three.js components
│   │   ├── dashboard/        # Evolution dashboard
│   │   ├── marketplace/      # Trading interface
│   │   └── common/           # Shared components
│   ├── pages/
│   ├── styles/
│   ├── hooks/                # Custom React hooks
│   ├── utils/                # Utility functions
│   └── package.json
├── mobile/                    # React Native app
│   ├── src/
│   ├── android/
│   ├── ios/
│   └── package.json
├── sdks/                      # Gaming platform SDKs
│   ├── unity/
│   ├── unreal/
│   └── web3-gaming/
├── docs/                      # Documentation
├── scripts/                   # Automation scripts
└── README.md
```

## 🔧 Smart Contract Architecture

### Core Contracts

#### DynamicNFT.sol
Main ERC-721 contract with enhanced functionality:
- Upgradeable metadata system
- Evolution state tracking
- AI personality storage
- Cross-chain compatibility flags
- Utility scoring mechanism

```solidity
contract DynamicNFT is ERC721Upgradeable, AccessControlUpgradeable {
    struct NFTData {
        uint256 evolutionStage;
        uint256 utilityScore;
        uint256 lastEvolution;
        bytes32 personalityHash;
        uint256[] traits;
        mapping(uint256 => uint256) chainStates;
    }
}
```

#### EvolutionEngine.sol
Handles all NFT transformations:
- Time-based evolution triggers
- Usage-based upgrade system
- Chainlink VRF for randomness
- Real-world data integration

```solidity
contract EvolutionEngine is VRFConsumerBaseV2, AccessControlUpgradeable {
    function triggerEvolution(uint256 tokenId) external;
    function processRandomEvolution(uint256 requestId, uint256[] memory randomWords) internal;
    function checkEvolutionCriteria(uint256 tokenId) public view returns (bool);
}
```

### Contract Deployment

Deploy contracts in the following order:

1. **Core Infrastructure:**
```bash
npx hardhat run scripts/01-deploy-infrastructure.js --network mainnet
```

2. **NFT Contracts:**
```bash
npx hardhat run scripts/02-deploy-nft-contracts.js --network mainnet
```

3. **Evolution System:**
```bash
npx hardhat run scripts/03-deploy-evolution.js --network mainnet
```

4. **Marketplace:**
```bash
npx hardhat run scripts/04-deploy-marketplace.js --network mainnet
```

## 🎮 Gaming SDK Integration

### Unity Plugin

```csharp
using EvoNFT.Unity;

public class GameManager : MonoBehaviour 
{
    private EvoNFTManager nftManager;
    
    void Start() 
    {
        nftManager = new EvoNFTManager();
        nftManager.Initialize("your_api_key");
    }
    
    async void UseNFTInGame(string tokenId) 
    {
        var nftData = await nftManager.GetNFTData(tokenId);
        ApplyNFTBoosts(nftData.traits);
        await nftManager.RecordUsage(tokenId, "game_interaction");
    }
}
```

### Web3 Gaming API

```javascript
import { EvoNFTSDK } from '@evonft/web3-gaming';

const sdk = new EvoNFTSDK({
  apiKey: 'your_api_key',
  network: 'mainnet'
});

// Use NFT in game
const nftData = await sdk.getNFT(tokenId);
const gameBoosts = sdk.calculateGameBoosts(nftData.traits);

// Record usage for evolution
await sdk.recordGameplay(tokenId, {
  gameId: 'your_game_id',
  sessionDuration: 1800,
  achievements: ['level_up', 'boss_defeated']
});
```

## 📊 API Documentation

### GraphQL Schema

```graphql
type NFT {
  id: ID!
  tokenId: String!
  owner: String!
  evolutionStage: Int!
  utilityScore: Float!
  traits: [Trait!]!
  personalityData: PersonalityData
  evolutionHistory: [Evolution!]!
  crossChainStates: [ChainState!]!
}

type Query {
  nft(tokenId: String!): NFT
  nfts(owner: String, limit: Int, offset: Int): [NFT!]!
  marketplace(filters: MarketplaceFilters): [MarketplaceListing!]!
}

type Mutation {
  triggerEvolution(tokenId: String!): Evolution!
  stakeNFT(tokenId: String!, poolId: String!): StakingResult!
  createListing(input: CreateListingInput!): MarketplaceListing!
}
```

### REST API Endpoints

```
GET    /api/nfts/:tokenId              - Get NFT data
POST   /api/nfts/:tokenId/evolve       - Trigger evolution
GET    /api/marketplace                - Get marketplace listings
POST   /api/marketplace/list           - Create new listing
GET    /api/analytics/portfolio        - Get portfolio analytics
POST   /api/gaming/record-usage        - Record game usage
GET    /api/staking/pools              - Get staking pools
POST   /api/staking/stake              - Stake NFT
```

## 🧪 Testing

### Smart Contract Tests

```bash
cd contracts
npm run test                    # Run all tests
npm run test:coverage          # Generate coverage report
npm run test:gas-report        # Generate gas usage report
```

### Frontend Tests

```bash
cd frontend
npm run test                   # Run Jest tests
npm run test:e2e              # Run Playwright E2E tests
npm run test:lighthouse       # Performance testing
```

### Backend Tests

```bash
cd backend
npm run test                   # Run unit tests
npm run test:integration      # Run integration tests
npm run test:load             # Load testing with Artillery
```

## 🚢 Deployment

### Smart Contract Deployment

1. **Testnet Deployment:**
```bash
npm run deploy:goerli
npm run deploy:mumbai
npm run verify:goerli
```

2. **Mainnet Deployment:**
```bash
npm run deploy:mainnet
npm run deploy:polygon
npm run verify:mainnet
```

### Application Deployment

1. **Backend (AWS/Docker):**
```bash
docker build -t evonft-backend ./backend
docker push your-registry/evonft-backend:latest
```

2. **Frontend (Vercel/Netlify):**
```bash
cd frontend
npm run build
npm run export
```

## 📈 Monitoring & Analytics

### Performance Metrics

- **Smart Contract Gas Usage**: Monitor evolution costs
- **API Response Times**: Track backend performance
- **Frontend Core Web Vitals**: User experience metrics
- **Cross-Chain Transaction Times**: Bridge performance

### Business Metrics

- **Daily Active Users (DAU)**
- **Monthly Trading Volume**
- **Evolution Frequency**
- **Utility Score Distribution**
- **Cross-Chain Activity**

## 🔒 Security Considerations

### Smart Contract Security

- ✅ Formal verification with Certora
- ✅ Multi-sig governance with Gnosis Safe
- ✅ Timelock mechanisms for upgrades
- ✅ Emergency pause functionality
- ✅ Comprehensive audit reports

### Infrastructure Security

- ✅ Rate limiting on all APIs
- ✅ DDoS protection via Cloudflare
- ✅ End-to-end encryption for sensitive data
- ✅ Regular security assessments
- ✅ Automated vulnerability scanning

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Standards

- **Solidity**: Follow [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- **JavaScript/TypeScript**: ESLint + Prettier configuration
- **Testing**: Minimum 90% code coverage required
- **Documentation**: JSDoc for functions, comprehensive README updates

## 🙏 Acknowledgments

- **Chainlink** - Oracle and VRF services
- **OpenZeppelin** - Smart contract security standards
- **Three.js** - 3D graphics rendering
- **The Graph** - Decentralized indexing protocol
- **IPFS** - Distributed storage network

---

**Built with ❤️ by the EvoNFT Team**

*Creating the future of living digital assets*
