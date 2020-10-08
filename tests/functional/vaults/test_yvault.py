import pytest
import brownie

from brownie import yVault

VAULTS = [yVault]


@pytest.mark.parametrize("Vault", VAULTS)
def test_vault_deployment(gov, token, controller, Vault, check_vault_deployment):
    check_vault_deployment(gov, token, controller, Vault)


@pytest.mark.parametrize("Vault", VAULTS)
def test_vault_setParams(
    accounts, gov, token, controller, Vault, vault_params, check_vault_setParams
):
    getter = vault_params[0]
    setter = vault_params[1]
    val = vault_params[2]
    check_vault_setParams(accounts, gov, token, controller, getter, setter, val, Vault)
