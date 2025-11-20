.PHONY: build test deploy deploy-local clean fmt snapshot flatten flatten-nft flatten-escrow

# Network configuration
RPC_URL ?= https://sepolia-rpc.scroll.io
SCRIPT := script/DeployWorkNFT.s.sol:DeployMintwork

# Build the project
build:
	forge build

# Run tests
test:
	forge test

# Format code
fmt:
	forge fmt

# Generate gas snapshots
snapshot:
	forge snapshot

# Clean build artifacts
clean:
	forge clean

# Flatten contracts
flatten: flatten-nft flatten-escrow
	@echo "All contracts flattened successfully!"

# Flatten WorkNFT contract
flatten-nft:
	@echo "Flattening WorkNFT contract..."
	@mkdir -p flattens
	forge flatten src/Mintwork_NFT.sol -o flattens/WorkNFT.flatten.sol
	@echo "WorkNFT flattened to flattens/WorkNFT.flatten.sol"

# Flatten WorkMarketplace contract
flatten-escrow:
	@echo "Flattening WorkMarketplace contract..."
	@mkdir -p flattens
	forge flatten src/Mintwork_Escrow.sol -o flattens/WorkMarketplace.flatten.sol
	@echo "WorkMarketplace flattened to flattens/WorkMarketplace.flatten.sol"

# Deploy to Scroll Sepolia
deploy:
	@echo "Deploying to Scroll Sepolia..."
	@if [ -z "$$PRIVATE_KEY" ]; then \
		echo "Error: PRIVATE_KEY environment variable is not set"; \
		exit 1; \
	fi
	@if [ -z "$$WETH_ADDRESS" ]; then \
		echo "Error: WETH_ADDRESS environment variable is not set"; \
		exit 1; \
	fi
	forge script $(SCRIPT) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--verify \
		-vvvv

# Deploy to local Anvil node
deploy-local:
	@echo "Deploying to local Anvil node..."
	forge script $(SCRIPT) \
		--rpc-url http://localhost:8545 \
		--broadcast \
		-vvvv

# Deploy without verification (faster)
deploy-no-verify:
	@echo "Deploying to Scroll Sepolia (without verification)..."
	@if [ -z "$$PRIVATE_KEY" ]; then \
		echo "Error: PRIVATE_KEY environment variable is not set"; \
		exit 1; \
	fi
	@if [ -z "$$WETH_ADDRESS" ]; then \
		echo "Error: WETH_ADDRESS environment variable is not set"; \
		exit 1; \
	fi
	forge script $(SCRIPT) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		-vvvv

# Help command
help:
	@echo "Available commands:"
	@echo "  make build          - Build the project"
	@echo "  make test           - Run tests"
	@echo "  make fmt            - Format code"
	@echo "  make snapshot       - Generate gas snapshots"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make flatten        - Flatten both contracts"
	@echo "  make flatten-nft    - Flatten WorkNFT contract only"
	@echo "  make flatten-escrow  - Flatten WorkMarketplace contract only"
	@echo "  make deploy         - Deploy to Scroll Sepolia (with verification)"
	@echo "  make deploy-no-verify - Deploy to Scroll Sepolia (without verification)"
	@echo "  make deploy-local   - Deploy to local Anvil node"
	@echo ""
	@echo "Environment variables required for deploy:"
	@echo "  PRIVATE_KEY         - Your private key (without 0x prefix)"
	@echo "  WETH_ADDRESS        - WETH contract address"
	@echo ""
	@echo "Example:"
	@echo "  export PRIVATE_KEY=your_key"
	@echo "  export WETH_ADDRESS=0x5300000000000000000000000000000000000004"
	@echo "  make deploy"

