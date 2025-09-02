.PHONY: help install build test deploy clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	npm install
	forge install

build: ## Build contracts
	forge build

test: ## Run tests
	forge test

test-fork: ## Run tests with mainnet fork
	forge test --fork-url ${MAINNET_RPC_URL}

test-gas: ## Run tests with gas report
	forge test --gas-report

deploy-mainnet: ## Deploy to mainnet
	forge script scripts/Deploy.s.sol --rpc-url ${MAINNET_RPC_URL} --broadcast --verify

deploy-testnet: ## Deploy to testnet
	forge script scripts/Deploy.s.sol:deployTestnet --rpc-url ${GOERLI_RPC_URL} --broadcast

verify: ## Verify contracts on Etherscan
	./scripts/verify.sh

keeper: ## Run keeper bot
	npm run keeper

keeper-dev: ## Run keeper in development mode
	npm run keeper:dev

clean: ## Clean build artifacts
	forge clean
	rm -rf out cache node_modules dist logs/*.log