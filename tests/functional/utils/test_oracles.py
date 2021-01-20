import pytest

from brownie import (
    BTCOSMedianizer,
    ETHOSMedianizer,
)

ORACLES = [BTCOSMedianizer, ETHOSMedianizer]


@pytest.mark.parametrize(
    "Oracle,osm,medianizer",
    [
        (
            BTCOSMedianizer,
            "0xf185d0682d50819263941e5f4EacC763CC5C6C42",
            "0x9B8Eb8b3d6e2e0Db36F41455185FEF7049a35CaE",
        ),
        (
            ETHOSMedianizer,
            "0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763",
            "0x729D19f657BD0614b4985Cf1D82531c67569197B",
        ),
    ],
)
def test_hardcoded_config(a, Oracle, osm, medianizer):
    oracle = a[0].deploy(Oracle)
    assert oracle.OSM() == osm
    assert oracle.MEDIANIZER() == medianizer


@pytest.mark.parametrize("Oracle", ORACLES)
def test_governance(a, gov, Oracle):
    oracle = a[0].deploy(Oracle)
    assert oracle.governance() == a[0]
    oracle.setGovernance(gov)
    assert oracle.governance() == gov


@pytest.mark.parametrize("Oracle", ORACLES)
def test_whitelist(a, gov, Oracle):
    oracle = a[0].deploy(Oracle)
    assert not oracle.authorized(gov)
    oracle.setAuthorized(gov)
    assert oracle.authorized(gov)
    oracle.revokeAuthorized(gov)
    assert not oracle.authorized(gov)


@pytest.mark.parametrize("Oracle", ORACLES)
@pytest.mark.parametrize("func", ["read", "foresight"])
def test_read(a, Oracle, func):
    oracle = a[0].deploy(Oracle)
    price, osm = getattr(oracle, func)()
    assert price > 0
    assert not osm


@pytest.mark.xfail
@pytest.mark.parametrize("func", ["read", "foresight"])
def test_read_bud(a, interface, OSMedianizer, func):
    oracle = OSMedianizer.at("0x82c93333e4E295AA17a05B15092159597e823e8a")
    osm = interface.OracleSecurityModule(oracle.OSM())
    assert osm.bud(oracle), "kiss first"
    reader = a[0]  # TODO: someone authorized
    assert oracle.authorized(reader)
    price, osm = getattr(oracle, func)({"from": reader})
    assert price > 0
    assert osm
