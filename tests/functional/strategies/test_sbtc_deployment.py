def test_sbtc_fix(ychad, accounts, Contract):
    strategist = accounts.at('0x1ea056C13F8ccC981E51c5f1CDF87476666D0A74', force=True)
    want = '0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3'
    vault = Contract('0x7Ff566E1d69DEfF32a7b244aE7276b9f90e9D0f6')
    controller = Contract('0x9E65Ad11b299CA0Abefc2799dDB6314Ef2d91080')
    strategy = Contract('0xeB8DEfc602E20b113B2E5a30498FB6E6A46f214F')
    strategy_proxy = Contract('0x7A99923aA2efa71178BB11294349EC1F6b23a814')

    strategy.setStrategist(strategist, {'from': ychad})
    controller.approveStrategy(want, strategy, {"from": ychad})
    controller.setStrategy(want, strategy, {"from": ychad})
    strategy_proxy.approveStrategy(strategy, {"from": ychad})
    
    vault.earn({'from': ychad})
    strategy.harvest({'from': strategist})
    controller.withdrawAll(want, {'from': ychad})
