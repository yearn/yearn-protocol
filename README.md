# [Yearn Protocol](https://yearn.finance/) &middot; [![GitHub license](https://img.shields.io/badge/license-AGPL-blue.svg)](https://github.com/iearn-finance/yearn-protocol/blob/master/LICENSE)

Yearn Protocol is a set of Ethereum Smart Contracts focused on creating a simple way to generate high risk-adjusted returns for depositors of various assets via best-in-class lending protocols, liquidity pools, and community-made yield farming strategies on Ethereum.

Before getting started with this repo, please read:

* [Andre's Overview Blog Post](https://medium.com/iearn/yearn-finance-v2-af2c6a6a3613), describing how yearn.finance works
* The [Delegated Vaults Blog Post](https://medium.com/iearn/delegated-vaults-explained-fa81f1c3fce2), explaining how the delegated vaults work
* [yETH Vault Explained](https://medium.com/iearn/yeth-vault-explained-c29d6b93a371), describing how the yETH vault works

## Requirements
Requirements for running the project: 
* Python 3.8 local development environment and NodeJs 10.x development environment for Ganache
* Brownie local environment setup. See here for instructions: [ETH Brownie](https://github.com/eth-brownie/brownie) 
* Local env variables for [Etherscan API](https://etherscan.io/apis) and [Infura](https://infura.io/). ETHERSCAN_TOKEN, WEB3_INFURA_PROJECT_ID
* Local Ganache environment installed with `npm install -g ganache-cli@6.10.1`

## Installation

To run the yearn protocol, pull the repository from GitHub and install its dependencies. You will need [yarn](https://yarnpkg.com/lang/en/docs/install/) or [npm](https://docs.npmjs.com/cli/install) installed.

    git clone https://github.com/iearn-finance/yearn-protocol/
    cd yearn-protocol
    yarn install --lock-file # or `npm install`


Compile the Smart Contracts
`brownie compile`

## Tests

Running tests:
`brownie test -s`

Running tests with coverage:
`brownie test -s --coverage`

## Linting
Checking linter rules
`yarn lint:check`

Fixing linter rules
`yarn lint:fix`

## Security

For security concerns, please visit [Bug Bounty](https://github.com/iearn-finance/yearn-protocol/blob/develop/SECURITY.md) or email [yearn-security@pm.me](yearn-security@pm.me).

## Documentation

You can read more about yearn finance on our [Documentation Site](https://docs.yearn.finance/).

## Discussion

For questions not covered in the docs regarding the Yearn Protocol, please visit [our Discord server](https://discord.gg/CY3RdS).