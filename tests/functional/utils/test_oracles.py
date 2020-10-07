import pytest


@pytest.fixture
def oracle(a, BTCOSMedianizer):
    yield a[0].deploy(BTCOSMedianizer)


def test_hardcoded_config(a, oracle):
    assert oracle.OSM() == "0xf185d0682d50819263941e5f4EacC763CC5C6C42"
    assert oracle.MEDIANIZER() == "0x9B8Eb8b3d6e2e0Db36F41455185FEF7049a35CaE"


def test_governance(a, gov, oracle):
    assert oracle.governance() == a[0]
    oracle.setGovernance(gov)
    assert oracle.governance() == gov


def test_whitelist(gov, oracle):
    assert not oracle.authorized(gov)
    oracle.setAuthorized(gov)
    assert oracle.authorized(gov)
    oracle.revokeAuthorized(gov)
    assert not oracle.authorized(gov)


@pytest.mark.parametrize("func", ["read", "foresight"])
def test_read(a, oracle, func):
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
