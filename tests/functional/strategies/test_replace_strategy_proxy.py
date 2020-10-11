def test_replace_strategy_proxy(
    Contract,
    ychad,
    interface,
    StrategyCurveBTCVoterProxy,
    StrategyCurveYBUSDVoterProxy,
    StrategyCurveYVoterProxy,
    StrategyProxy,
):
    controller = Contract("0x9E65Ad11b299CA0Abefc2799dDB6314Ef2d91080")
    voter_proxy = Contract("0xF147b8125d2ef93FB6965Db97D6746952a133934")
    tokens = {
        "ycrv": [
            "0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8",
            StrategyCurveYVoterProxy,
        ],
        "busd": [
            "0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B",
            StrategyCurveYBUSDVoterProxy,
        ],
        "sbtc": [
            "0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3",
            StrategyCurveBTCVoterProxy,
        ],
    }
    print("Deploy fixed strategy proxy")
    strategy_proxy = StrategyProxy.deploy({"from": ychad})

    print("Migrate to fixed strategies")
    for name, (token, strat) in tokens.items():
        print(name, strat._name)
        vault = interface.YearnVault(controller.vaults(token))
        strategy = strat.deploy(controller, {"from": ychad})
        print("deployed", strategy)
        strategy.setProxy(strategy_proxy, {"from": ychad})
        strategy_proxy.approveStrategy(strategy, {"from": ychad})
        old_strat = controller.strategies(token)
        print(old_strat)
        controller.approveStrategy(token, strategy, {"from": ychad})
        controller.setStrategy(token, strategy, {"from": ychad})
        controller.revokeStrategy(token, old_strat, {"from": ychad})
        print("vault balance:", vault.balance().to("ether"))

    voter_proxy.setStrategy(strategy_proxy, {"from": ychad})
    for name, (token, strat) in tokens.items():
        vault = interface.YearnVault(controller.vaults(token))
        before = vault.balance()
        vault.earn({"from": ychad})
        print("vault balance:", before.to("ether"))
        print("vault available:", vault.available().to("ether"))
        assert vault.available() < vault.balance()
        # test only sanity check that we didn't break the withdraw flow
        controller.withdrawAll(token, {"from": ychad})
        print("vault balance:", vault.balance().to("ether"))
        assert vault.balance() == before
