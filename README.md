# Yearn Protocol

[![GitHub license](https://img.shields.io/badge/license-AGPL-blue.svg)](https://github.com/iearn-finance/yearn-protocol/blob/master/LICENSE)
![Lint](https://github.com/iearn-finance/yearn-protocol/workflows/Lint/badge.svg)
![Test](https://github.com/iearn-finance/yearn-protocol/workflows/Test/badge.svg)

Yearn Protocol is a set of Ethereum Smart Contracts focused on creating a simple way to generate high risk-adjusted returns for depositors of various assets via best-in-class lending protocols, liquidity pools, and community-made yield farming strategies on Ethereum.

Before getting started with this repo, please read:

-   [Andre's Overview Blog Post](https://medium.com/iearn/yearn-finance-v2-af2c6a6a3613), describing how yearn.finance works.
-   The [Delegated Vaults Blog Post](https://medium.com/iearn/delegated-vaults-explained-fa81f1c3fce2), explaining how the delegated vaults work.
-   [yETH Vault Explained](https://medium.com/iearn/yeth-vault-explained-c29d6b93a371), describing how the yETH vault works.

### Requirements

To run the project you need:

-   Python 3.8 local development environment and Node.js 10.x development environment for Ganache.
-   Brownie local environment setup. See instructions: [ETH Brownie](https://github.com/eth-brownie/brownie).
-   Local env variables for [Etherscan API](https://etherscan.io/apis) and [Infura](https://infura.io/) (`ETHERSCAN_TOKEN`, `WEB3_INFURA_PROJECT_ID`).
-   Local Ganache environment installed with `npm install -g ganache-cli@6.11`.

### Installation

To run the yearn protocol, pull the repository from GitHub and install its dependencies. You will need [yarn](https://yarnpkg.com/lang/en/docs/install/) installed.

```bash
git clone https://github.com/iearn-finance/yearn-protocol
cd yearn-protocol
yarn install --lock-file
```

Compile the Smart Contracts:

```bash
brownie compile
```

### Tests

Run tests:

```bash
brownie test -s
```

Run tests with coverage:

```bash
brownie test -s --coverage
```

### Formatting

Check linter rules for `*.json` and `*.sol` files:

```bash
yarn lint:check
```

Fix linter errors for `*.json` and `*.sol` files:

```bash
yarn lint:fix
```

Check linter rules for `*.py` files:

```bash
black . --check --config black-config.toml
```

Fix linter errors for `*.py` files:

```bash
black . --config black-config.toml
```

### Security

For security concerns, please visit [Bug Bounty](https://github.com/iearn-finance/yearn-protocol/blob/develop/SECURITY.md).

### Documentation

You can read more about yearn finance on our documentation [webpage](https://docs.yearn.finance).

### Discussion

For questions not covered in the docs, please visit [our Discord server](http://discord.yearn.finance).
