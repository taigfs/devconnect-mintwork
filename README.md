# Mintwork - Work Marketplace on Scroll

Decentralized job marketplace with WETH escrow and Work Credential NFTs on Scroll Sepolia.

## Overview

Mintwork is a smart contract system that enables:
- **Job Creation**: Requesters create jobs and lock WETH in escrow
- **Work Submission**: Workers claim jobs and submit their work
- **Payment & NFT Minting**: Upon approval, workers receive WETH payment and a Work Credential NFT

## Contracts

- **`WorkNFT.sol`**: ERC-721 NFT that serves as a verifiable credential of completed work
- **`WorkMarketplace.sol`**: Escrow-based marketplace that manages jobs and payments

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Private key with ETH on Scroll Sepolia
- WETH contract address on Scroll Sepolia

## Setup

1. **Clone and install dependencies:**
```bash
git clone <your-repo>
cd devconnect-mintwork
forge install
```

2. **Configure environment variables:**
```bash
# Copy the example file
cp env.example .env

# Edit .env with your values
PRIVATE_KEY=your_private_key_here
WETH_ADDRESS=0x5300000000000000000000000000000000000004
```

3. **Build:**
```bash
forge build
```

## Deployment

### Deploy to Scroll Sepolia

**Option 1: Using Makefile (Recommended)**
```bash
# Export environment variables
export PRIVATE_KEY="your_private_key_here"
export WETH_ADDRESS="0x5300000000000000000000000000000000000004"

# Deploy contracts
make deploy
```

**Option 2: Using .env file**
```bash
# Load environment variables
source .env

# Deploy contracts
forge script script/DeployWorkNFT.s.sol:DeployMintwork \
    --rpc-url https://sepolia-rpc.scroll.io \
    --broadcast \
    --verify \
    -vvvv
```

**Option 3: Using export directly**
```bash
# Export environment variables
export PRIVATE_KEY="your_private_key_here"
export WETH_ADDRESS="0x5300000000000000000000000000000000000004"

# Deploy contracts
forge script script/DeployWorkNFT.s.sol:DeployMintwork \
    --rpc-url https://sepolia-rpc.scroll.io \
    --broadcast \
    --verify \
    -vvvv
```

### Makefile Commands

```bash
make build          # Build the project
make test           # Run tests
make fmt            # Format code
make deploy         # Deploy to Scroll Sepolia (with verification)
make deploy-no-verify # Deploy without verification (faster)
make deploy-local    # Deploy to local Anvil node
make help           # Show all available commands
```

### Network Information

**Scroll Sepolia Testnet:**
- RPC URL: `https://sepolia-rpc.scroll.io`
- Chain ID: `534351`
- Currency: ETH
- Explorer: https://sepolia.scrollscan.com

## Development

### Build
```bash
forge build
```

### Test
```bash
forge test
```

### Format
```bash
forge fmt
```

### Gas Snapshots
```bash
forge snapshot
```

### Local Testing with Anvil
```bash
# Start local node
anvil

# Deploy to local node
forge script script/DeployWorkNFT.s.sol:DeployMintwork \
    --rpc-url http://localhost:8545 \
    --broadcast
```

## Architecture

### Deployment Flow
1. Deploy `WorkNFT` contract
2. Deploy `WorkMarketplace` contract with WETH and WorkNFT addresses
3. Transfer WorkNFT ownership to WorkMarketplace (allows marketplace to mint NFTs)

### Job Lifecycle
1. **Create Job**: Requester creates job and locks WETH in escrow
2. **Take Job**: Worker claims the job
3. **Submit Work**: Worker submits delivery URL
4. **Approve Work**: Requester approves → Worker receives WETH + Work Credential NFT
5. **Cancel Job**: Requester can cancel before job is taken (refund)

## Smart Contract Functions

### WorkMarketplace

- `createJob(reward, deadline, title, description)` - Create a new job with WETH escrow
- `takeJob(jobId)` - Claim a job
- `submitWork(jobId, deliveryUrl)` - Submit completed work
- `approveWork(jobId)` - Approve work and trigger payment + NFT mint
- `cancelJob(jobId)` - Cancel job and refund WETH (only if not taken)

### WorkNFT

- `mintWorkNft(...)` - Mint Work Credential NFT (only callable by WorkMarketplace)

## Security Features

- ✅ ReentrancyGuard on payment functions
- ✅ Ownable access control
- ✅ WETH held in escrow until approval
- ✅ Only marketplace can mint NFTs

## Troubleshooting

**Error: "contract source info format must be..."**
- Make sure to specify the contract name: `script/DeployWorkNFT.s.sol:DeployMintwork`

**Error: "WETH address zero"**
- Ensure `WETH_ADDRESS` environment variable is set

**Verification fails:**
- You may need a Scrollscan API key for contract verification
- Add to .env: `ETHERSCAN_API_KEY=your_scrollscan_api_key`

## License

MIT
