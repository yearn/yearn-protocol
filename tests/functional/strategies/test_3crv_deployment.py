from typing import Container


def test_3crv(ychad, accounts, StrategyCurve3CrvVoterProxy, StrategyProxy, Contract, chain):
    """
    1. StrategyCurve3CrvVoterProxy deploy
    2. StrategyProxy deploy
    3. CurveYCRVVoter.setStrategy(StrategyProxy)
    4. Controller.setVault(3Crv, y3Crv)
    """
    user = accounts.at("0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11", force=True)
    deposit = Contract('0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7')
    dai = Contract('0x6B175474E89094C44Da98b954EedeAC495271d0F')

    voter_proxy = Contract('0xF147b8125d2ef93FB6965Db97D6746952a133934')
    controller = Contract('0x9E65Ad11b299CA0Abefc2799dDB6314Ef2d91080')
    
    strategy = StrategyCurve3CrvVoterProxy.deploy(controller, {'from': ychad})
    want = Contract(strategy.want())
    vault = Contract(controller.vaults(want))
    strategy_proxy = StrategyProxy.deploy({'from': ychad})
    voter_proxy.setStrategy(strategy_proxy, {'from': ychad})

    print('configure')
    strategy.setProxy(strategy_proxy, {'from': ychad})
    strategy_proxy.approveStrategy(strategy, {'from': ychad})
    assert strategy.proxy() == strategy_proxy
    assert strategy_proxy.strategies(strategy)

    controller.setVault(want, vault, {'from': ychad})
    assert controller.vaults(want) == vault
    
    print('activate')
    controller.approveStrategy(want, strategy, {'from': ychad})
    controller.setStrategy(want, strategy, {'from': ychad})
    assert controller.strategies(want) == strategy

    dai.approve(deposit, dai.balanceOf(user), {'from': user})
    deposit.add_liquidity([dai.balanceOf(user), 0, 0], 0, {'from': user})
    print('user has', want.balanceOf(user).to('ether'), 'lp tokens')

    want.approve(vault, want.balanceOf(user), {'from': user})
    vault.deposit(want.balanceOf(user), {'from': user})
    print('vault balance of user', vault.balanceOf(user).to('ether'))
    
    before = vault.balance()
    print('vault balance', before.to('ether'))
    vault.earn({'from': ychad})
    print('strategy balance', strategy.balance().to('ether'))
    
    # can't test cause of ganache-cli bug
    # strategy.harvest({'from': ychad})
    
    controller.withdrawAll(want, {'from': ychad})
    assert vault.balance() >= before
