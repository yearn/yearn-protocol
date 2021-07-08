import pytest
import brownie

oracles = {
    "BTC/USD": "0xf185d0682d50819263941e5f4EacC763CC5C6C42",
    "ETH/USD": "0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763",
    "YFI/USD": "0x5F122465bCf86F45922036970Be6DD7F58820214",
}


@pytest.mark.parametrize("name", oracles)
def test_maker_oracle(MakerOracle, accounts, interface, name):
    osm_mom = accounts.at("0x76416A4d5190d071bfed309861527431304aA14f", force=True)
    source = interface.OracleSecurityModule(oracles[name])
    deployer, reader = accounts[:2]
    oracle = MakerOracle.deploy(source, {"from": deployer})
    oracle.set_user(reader, True)
    assert oracle.users(reader)
    for func in [oracle.peek, oracle.peep]:
        with brownie.reverts("not user"):
            func()
        with brownie.reverts("not bud"):
            func({"from": reader})
    source.kiss(oracle, {"from": osm_mom})
    for func in [oracle.peek, oracle.peep]:
        val, has = func({"from": reader})
        print(val.to("ether"), has)
        assert val > 0
        assert has


def test_maker_oracle_auth(MakerOracle, accounts):
    deployer, owner, rando = accounts[:3]
    oracle = MakerOracle.deploy(oracles["YFI/USD"], {"from": deployer})
    assert oracle.owner() == deployer
    oracle.set_owner(owner)
    assert oracle.owner() == owner
    with brownie.reverts():
        oracle.set_owner(rando, {"from": rando})
