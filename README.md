# Proveably Random Raffle Contracts

## About
This code creates a raffle smart contract that is proveably random in result.

# Getting Started

## Requirements You will need to have git and foundry installed.
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
 - Run `git --version`. You see an output like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
 - Run `forge --version` you should see an output like `forge 0.2.0 (ec3f9bd 2023-09-19T13:44:30.009787069Z)` if you've done it right.

## Quickstart

```
git clone https://github.com/chthsol/foundry-foundry-smart-contract-lottery-f23
cd foundry-foundry-smart-contract-lottery-f23
forge build
```
# Usage

## Start a local node
```
make anvil
```

## Install chainlink Library
```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

## Deploy
```
make deploy
```
## Testing

Run all tests.
```
forge test
```

You can run individual tests of each function with the --match-test option.
```
forge test --match-test testFunctionName
```

To run tests in a forked environment, use the --fork-url EVM option.
You will need to have set up a .env with the appropriate rpc-url to run a fork environment.
See "Setup environment variables" in "Deploy to a testnet" below.
```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test coverage.

Check test coverage
```
forge coverage
```

# Deploy to a testnet.

1. Setup environment variables.

Create a .env file and add `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables.

- `PRIVATE_KEY` :  Private key of the account you will use to deploy. **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
- `SEPOLIA_RPC_URL`: Url of the Sepolia testnet that you will use.

2. You will need testnet ETH to deploy to testnet.

If you have an Alchemy account you can get tesnet ETH at the appropriate Alchemy ETH faucet.
[sepoliafaucet.com](https://sepoliafaucet.com/)

3. You will also need testnet Link and a link account.

If you already have a link account and subscription, you can update scripts/Helperconfig.s.sol with your information. It will also add your contract as a consumer.

To register a chainlink automation upkeep, go to automation.chain.link and register a new upkeep. Choose Custom logic as your trigger
mechanism for automation.

To get test chainlink (for Sepolia testnet) you can go here: 
https://faucets.chain.link/

4. Deploy
```
make deploy ARGS="--network sepolia"
```
If the initial deploy created a chainlink subscription for you, you will need to update the helperconfig with your
subscription ID before runing addConsumer or fundSubstion Interactions.

## Scripts

Once you have deployed to a local or testnet, you can run the scripts.
Enter the raffle:
```
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```

Create a subscription:
```
make createSubscription ARGS="--network sepolia"
```

Enjoy!
