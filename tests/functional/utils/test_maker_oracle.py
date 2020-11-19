import brownie


def test_yfi_oracle(MakerOracle, accounts, Contract):
    osm_mom = accounts.at("0x76416A4d5190d071bfed309861527431304aA14f", force=True)
    yfi_usd_osm = Contract("0x5F122465bCf86F45922036970Be6DD7F58820214")
    deployer, reader = accounts[:2]
    oracle = MakerOracle.deploy(yfi_usd_osm, {"from": deployer})
    oracle.set_user(reader, True)
    brk_a = 345_592
    for func in [oracle.peek, oracle.peep]:
        with brownie.reverts("not user"):
            func()
        with brownie.reverts("not bud"):
            func({"from": reader})
    yfi_usd_osm.kiss["address"](oracle, {"from": osm_mom})
    for func in [oracle.peek, oracle.peep]:
        val, has = func({"from": reader})
        assert val.to("ether") > brk_a
        assert has
