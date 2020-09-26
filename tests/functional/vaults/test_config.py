import pytest
import brownie


def test_vault_deployment(gov, token, Vault):
    vault = gov.deploy(Vault, token, gov)
    # Addresses
    assert vault.governance() == gov
    assert vault.token() == token
    # UI Stuff
    assert vault.name() == "yearn " + token.name()
    assert vault.symbol() == "y" + token.symbol()
    assert vault.decimals() == token.decimals()


@pytest.mark.parametrize(
    "getter,setter,val",
    [
        ("emergencyShutdown", "setEmergencyShutdown", True),
        ("guardian", "setGuardian", None),
        ("governance", "setGovernance", None),
    ],
)
def test_vault_setParams(accounts, gov, token, getter, setter, val, Vault):
    if not val:
        # Can't access fixtures, so use None to mean an address literal
        val = accounts[1]

    guardian = accounts[9]
    vault = guardian.deploy(Vault, token, gov)

    # Only governance can set this param
    with brownie.reverts():
        getattr(vault, setter)(val, {"from": accounts[1]})
    getattr(vault, setter)(val, {"from": gov})
    assert getattr(vault, getter)() == val

    # When changing governance contract, make sure previous no longer has access
    if getter == "governance":
        with brownie.reverts():
            getattr(vault, setter)(val, {"from": gov})
