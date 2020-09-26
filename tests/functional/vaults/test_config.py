import pytest
import brownie

from brownie import (
    yVault,
    yWETH,
    yDelegatedVault,
)

VAULTS = [yVault, yWETH, yDelegatedVault]


@pytest.mark.parametrize("Vault", VAULTS)
def test_vault_deployment(gov, token, controller, Vault):
    vault = gov.deploy(Vault, token, controller)
    # Addresses
    assert vault.governance() == gov
    assert vault.controller() == controller
    assert vault.token() == token
    # UI Stuff
    assert vault.name() == "yearn " + token.name()
    assert vault.symbol() == "y" + token.symbol()
    assert vault.decimals() == token.decimals()


@pytest.mark.parametrize(
    "getter,setter,val",
    [
        ("min", "setMin", 9000),
        ("healthFactor", "setHealthFactor", 100),
        ("controller", "setController", None),
        ("governance", "setGovernance", None),
    ],
)
@pytest.mark.parametrize("Vault", VAULTS)
def test_vault_setParams(accounts, gov, token, controller, getter, setter, val, Vault):
    if not val:
        # Can't access fixtures, so use None to mean an address literal
        val = accounts[1]

    vault = gov.deploy(Vault, token, controller)

    if not hasattr(vault, getter):
        return  # Some combinations aren't valid

    # Only governance can set this param
    with brownie.reverts("!governance"):
        getattr(vault, setter)(val, {"from": accounts[1]})
    getattr(vault, setter)(val, {"from": gov})
    assert getattr(vault, getter)() == val

    # When changing governance contract, make sure previous no longer has access
    if getter == "governance":
        with brownie.reverts("!governance"):
            getattr(vault, setter)(val, {"from": gov})
