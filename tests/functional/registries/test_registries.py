import pytest
import brownie

from brownie import (
    yVault,
    yWETH,
    yDelegatedVault,
    YRegistryV2,
    StrategyCreamYFI,
    StrategyMKRVaultDAIDelegate,
    Controller,
)


def test_registry_deployment(gov):
    registry = gov.deploy(YRegistryV2, gov)
    assert registry.getName() == "YRegistryV2"
    assert registry.governance() == gov


def test_registry_add_vault(accounts, gov, rewards):
    token = "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e"
    controller = gov.deploy(Controller, rewards)
    vault = gov.deploy(yVault, token, controller)
    registry = gov.deploy(YRegistryV2, gov)
    strategy = gov.deploy(StrategyCreamYFI, controller)

    controller.setVault(token, vault, {"from": gov})
    controller.approveStrategy(token, strategy, {"from": gov})
    controller.setStrategy(token, strategy, {"from": gov})

    # Only governance can set this param
    with brownie.reverts("Only governance can call this function."):
        registry.addVault(vault, {"from": accounts[1]})
    registry.addVault(vault, {"from": gov})
    assert registry.getVault(0) == vault

    fields = ["vault", "controller", "token", "strategy", "is_wrapped", "is_delegated"]
    vaultInfo = dict(zip(fields, registry.getVaultInfo(vault)))
    assert vaultInfo["vault"] == vault
    assert vaultInfo["controller"] == controller
    assert vaultInfo["token"] == token
    assert vaultInfo["strategy"] == strategy
    assert vaultInfo["is_wrapped"] == False
    assert vaultInfo["is_delegated"] == False


def test_registry_add_delegated_vault(accounts, gov, rewards):
    token = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    controller = gov.deploy(Controller, rewards)
    vault = gov.deploy(yDelegatedVault, token, controller)
    registry = gov.deploy(YRegistryV2, gov)
    strategy = gov.deploy(StrategyMKRVaultDAIDelegate, controller)

    controller.setVault(strategy, vault, {"from": gov})
    controller.approveStrategy(vault, strategy, {"from": gov})
    controller.setStrategy(vault, strategy, {"from": gov})

    # Only governance can set this param
    with brownie.reverts("Only governance can call this function."):
        registry.addVault(vault, {"from": accounts[1]})
    registry.addDelegatedVault(vault, {"from": gov})
    assert registry.getVault(0) == vault

    fields = ["vault", "controller", "token", "strategy", "is_wrapped", "is_delegated"]
    vaultInfo = dict(zip(fields, registry.getVaultInfo(vault)))
    assert vaultInfo["vault"] == vault
    assert vaultInfo["controller"] == controller
    assert vaultInfo["token"] == token
    assert vaultInfo["strategy"] == strategy
    assert vaultInfo["is_wrapped"] == False
    assert vaultInfo["is_delegated"] == True
