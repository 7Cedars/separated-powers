# £ack this file was originally copied from https://github.com/Cyfrin/foundry-erc20-f23/blob/main/Makefile
-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules 
#&& git add . 
#&& git commit -m "modules"

# Install modules
install :; forge install foundry-rs/forge-std@v1.9.1 --no-commit && \
	forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit

# Update Dependencies
update :; forge update

# Build
build :; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil --steps-tracing --block-time 1

###############################
# 		Deploy Commands  				#
###############################
ANVIL_ARGS_0 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_0) --broadcast
ARB_SEPOLIA_TEST_ARGS := --fork-url $(ARB_SEPOLIA_RPC_URL) 
ARB_SEPOLIA_DEPLOY_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --chain-id 421614 --etherscan-api-key $(ARBISCAN_API_KEY) --verifier-url https://api-sepolia.arbiscan.io/api --verify -vvvv

anvilTest :; forge test $(ANVIL_ARGS_0)
arbSepoliaForkedTest :; forge test ${ARB_SEPOLIA_TEST_ARGS}

anvilDeploy :; forge script script/DeployAgDao.s.sol:DeployAgDao $(ANVIL_ARGS_0)
anvilConstitute :; forge script script/ConstituteAgDao.s.sol:ConstituteAgDao $(ANVIL_ARGS_0)

arbSepoliaTestDeploy :; forge script script/TestDeploy.s.sol:TestDeploy $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaDeploy :; forge script script/DeployAgDao.s.sol:DeployAgDao $(ARB_SEPOLIA_DEPLOY_ARGS)
arbSepoliaConstitute :;  forge script script/ConstituteAgDao.s.sol:ConstituteAgDao $(ARB_SEPOLIA_DEPLOY_ARGS)


