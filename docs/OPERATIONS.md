# Deploy a Strategy for V1

NOTE: This repo is encouraged to create multiple scripts for governance and dev multisig execution of complex transactions
https://github.com/iearn-finance/chief-multisig-officer

## Before deploying

-   [ ] Open a PR to https://github.com/iearn-finance/yearn-protocol or share a repo with the commit hash for review of the strategy
    -   Check for linting and CI to be green in PR
    -   (Optional) It's encouraged to add tests to PR for validating strategy
-   [ ] Coordinate with Core Dev for getting a review in board https://github.com/orgs/iearn-finance/projects/5

NOTE: This process doesn't have an exact ETA since it depends on existing backlog. If strategy has time sensitivity core devs can evaluate if it should be prioritized.

-   [ ] PR Approved and Peer Review Issue completed by at least 1 strategists + 1 core dev in board
-   [ ] If a vault deployment is needed, coordinate with core development for deployment.
    -   [ ] Etherscan verification for vault code
    -   [ ] Set deposit limit for Vault. `vault.setMin(2500)`
    -   [ ] Add vault to v1 resgistry. `v1registry.addVault(new_vault)`
    -   v1registry = '0x3eE41C098f9666ed2eA246f4D2558010e59d63A0'
-   [ ] If strategy is migrating from existing one:
    -   [ ] Ganache-fork dry run of migration and check balances and state is correct
-   [ ] Deploy Strategy
-   [ ] Tag github review issue https://github.com/orgs/iearn-finance/projects/5 with deployed version. Add mainnet addresses

## After deploying strategy

-   [ ] Run Etherscan verification for strategy
-   [ ] Run any strategy setting before handing governance to ychad.eth
-   [ ] Set Strategy governance to '0xfeb4acf3df3cdea7399794d0869ef76a6efaff52' (ychad.eth)
-   [ ] Provide steps in script format to core devs for governance multisig to run (see CMO repo in notes). Script will have at least these steps:
    -   Setup Controller. Check latest controller.
        -   If new vault for token run this step controller.setVault(token, vault)
        -   `controller.approveStrategy(token, strat)`
        -   `controller.setStrategy(token, strat)`
        -   `vault.earn()`
    -   [ ] Validate transaction execution in `https://ethtx.info`
-   [ ] Finish any HouseKeeping in PR to merge strategy into develop branch of yearn-protocol repo for tracking and documentation.

### Example Script:

```
# vault
weth = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
# controller
ctrl = '0x9E65Ad11b299CA0Abefc2799dDB6314Ef2d91080'
strategy = '0x39AFF7827B9D0de80D86De295FE62F7818320b76'

ctrl.approveStrategy(weth, strategy
ctrl.setStrategy(weth, strategy)
weth_vault.setMin(9900)
weth_vault.earn()

```

## After deploying a strategy that uses Curve Proxy

-   [ ] Run Etherscan verification for strategy
-   [ ] (Optional) Run any strategy setting before handing governance to ychad.eth
-   [ ] (Optional) If strategy needs a keep3r job, see the keep3r section for setup before moving to next steps.
-   [ ] Set Strategy governance to '0xfeb4acf3df3cdea7399794d0869ef76a6efaff52' (ychad.eth)
-   [ ] Provide steps in script format to core devs for governance multisig to run (see CMO repo in notes). Script will have at least these steps:
    -   Setup Controller. Check latest controller.
        -   If new vault for token run this step controller.setVault(token, vault)
        -   `controller.approveStrategy(token, strat)
        -   `controller.setStrategy(token, strat)
        -   `vault.earn()
    -   Setup gauge and Proxy
        -   `gauge = strat.gauge()` **VERY IMPORTANT: strategies cannot share same gauge**
        -   `proxy.approveStrategy(gauge, strat)`
    -   [ ] Validate transaction execution in `https://ethtx.info`
-   [ ] Finish any HouseKeeping in PR to merge strategy into develop branch of yearn-protocol repo for tracking and documentation.

### Example Script:

```
sUSD
proxy = '0x9a3a03C614dc467ACC3e81275468e033c98d960E'
controller = '0x9E65Ad11b299CA0Abefc2799dDB6314Ef2d91080'
scrv = '0xC25a3A3b969415c80451098fa907EC722572917F'
vault = '0x5533ed0a3b83F70c3c4a1f69Ef5546D3D4713E44'
strat = '0xd7F641697ca4e0e19F6C9cF84989ABc293D24f84'

gauge = strat.gauge()
controller.setVault(scrv, vault)
controller.approveStrategy(scrv, strat)
controller.setStrategy(scrv, strat)
proxy.approveStrategy(gauge, strat)

```

## Setting up Keep3r

> If your strategy security depends on a keep3r (i.e. yETH) calling either `tend`, `harvest` or others, please make sure to have a reliable working job before allowing funds in.

-   [ ] Check if any of the current SugarMommy-jobs are able to support your strategy

    > current jobs and guides can be found here: [strategies-keep3r repo](https://github.com/lbertenasco/strategies-keep3r)

-   [ ] **If yes**; Ask CoreDevs to add your strategy to the job
-   [ ] **If not**; Create a new SugarMommy Keep3r job
    -   [ ] Submit the New job as a PR to the [strategies-keep3r repo](https://github.com/lbertenasco/strategies-keep3r)
    -   [ ] Wait for it to be reviewed, deployed and enabled by CoreDevs

After the job is live you might want to:

-   [ ] Monitor the job, and upgrade it if you have any improvements. (Jobs are 100% disposables, and can, almost instantly, be swapped for a better version of themselves)

## Steps for updating StrategyProxy (Curve)

-   [ ] Validate migration in ganache fork to check a sample size or voter proxy strats can still call `earn()` and `harvest()` function don't have ay regression issues.
-   [ ] Setup CMO script for ychad.eth execution

### Example script:

```
proxy = '0x9a3a03C614dc467ACC3e81275468e033c98d960E'
voter = '0xF147b8125d2ef93FB6965Db97D6746952a133934'

## list all existing strategis that use proxy
_3crv = '0xC59601F0CC49baa266891b7fc63d2D5FE097A79D'
g3crv = '0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A'
busd = '0x112570655b32A8c747845E0215ad139661e66E7F'
gbusd = '0x69Fb7c45726cfE2baDeE8317005d3F94bE838840'
comp = '0x530da5aeF3c8f9CCbc75C97C182D6ee2284B643F'
gcomp = '0x7ca5b0a2910B33e9759DC7dDB0413949071D7575'
gusd = '0xD42eC70A590C6bc11e9995314fdbA45B4f74FABb'
ggusd = '0xC5cfaDA84E902aD92DD40194f0883ad49639b023'
musd = '0xBA0c07BBE9C22a1ee33FE988Ea3763f21D0909a0'
gmusd = '0x5f626c30EC1215f4EdCc9982265E8b1F411D1352'
btc = '0x6D6c1AD13A5000148Aa087E7CbFb53D402c81341'
gbtc = '0x705350c4BcD35c9441419DdD5d2f097d7a55410F'
eur = '0x22422825e2dFf23f645b04A3f89190B69f174659'
geur = '0x90Bb609649E0451E5aD952683D64BD2d1f245840'
y = '0x07DB4B9b3951094B9E278D336aDf46a036295DE7'
gy = '0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1'
# backscratcher
yveCRV = '0xc5bDdf9843308380375a611c18B50Fb9341f502A'
...

voter.setStrategy(proxy)

_3crv.setProxy(proxy)
busd.setProxy(proxy)
comp.setProxy(proxy)
gusd.setProxy(proxy)
musd.setProxy(proxy)
btc.setProxy(proxy)
eur.setProxy(proxy)
y.setProxy(proxy)
#...

# approve all strategies in proxy
proxy.approveStrategy(g3crv, _3crv)
proxy.approveStrategy(gbusd, busd)
proxy.approveStrategy(gcomp, comp)
proxy.approveStrategy(ggusd, gusd)
proxy.approveStrategy(gmusd, musd)
proxy.approveStrategy(gbtc, btc)
proxy.approveStrategy(geur, eur)
proxy.approveStrategy(gy, y)

# backscratcher setup with new proxy
yveCRV.acceptGovernance()
yveCRV.setFeeDistribution(proxy)
yveCRV.setProxy(proxy)
```

## Emergency Procedure

### Revoking a strategy

TBD @orb can detail what are the steps to move the vault and strat in emergency situation.
Stop deposits and possibly migrate strategy to mock rescue strat to send funds to governance.

1. `vault.setMin(0)`
2. `controller.approveStrategy(token, rescue_strategy)`
3. `controller.setStrategy(token, rescue_strategy)`
4. `vault.earn()`

These are the general steps for disabling deposit on a vault and detaching the vault with working strategy (maybe saving the funds too in extreme case of emergency).

> before step 2 and 3, there could be extra steps for customization. For example, a strategy could inlcude the logic of `migrate()`, so funds being rescued could be sent to the rescue_strategy for better unwinding. 3 triggers `withdrawAll()` which is not the best idea in all situations.
