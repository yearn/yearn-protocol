import pytest
import brownie


def test_addStrategy(web3, gov, token, rando, Vault, TestStrategy):
    # NOTE: Because the fixture has tokens in it already
    vault = gov.deploy(Vault, token, gov, gov)
    strategy = gov.deploy(TestStrategy, vault, gov)

    # Only governance can add a strategy
    with brownie.reverts():
        vault.addStrategy(strategy, 100, 1000, 10, {"from": rando})

    # A strategy can only be added if there is seed capital available for it
    with brownie.reverts():
        vault.addStrategy(strategy, 100, 1000, 10, {"from": gov})

    token.transfer(vault, 100, {"from": gov})  # addStrategy requires tokens
    assert vault.strategies(strategy) == [0, 0, 0, 0, 0, 0]

    vault.addStrategy(strategy, 100, 1000, 10, {"from": gov})
    assert vault.strategies(strategy) == [
        web3.eth.blockNumber,
        1000,
        10,
        web3.eth.blockNumber,
        100,
        0,
    ]


def test_updateStrategy(web3, gov, vault, strategy, rando):
    activation_block = web3.eth.blockNumber - 1  # Deployed right before test started
    current_debt = vault.strategies(strategy)[5]  # Accumalated debt already

    # Not just anyone can update a strategy
    with brownie.reverts():
        vault.updateStrategy(strategy, 1500, 15, {"from": rando})

    vault.updateStrategy(strategy, 1500, 15, {"from": gov})
    assert vault.strategies(strategy) == [
        activation_block,
        1500,
        15,
        activation_block,
        current_debt,
        0,
    ]


def test_revokeStrategy(web3, gov, vault, strategy, rando):
    activation_block = web3.eth.blockNumber - 1  # Deployed right before test started
    current_debt = vault.strategies(strategy)[5]  # Accumalated debt already

    # Not just anyone can revoke a strategy
    with brownie.reverts():
        vault.revokeStrategy(strategy, {"from": rando})

    vault.revokeStrategy(strategy, {"from": gov})
    assert vault.strategies(strategy) == [
        activation_block,
        0,
        1,
        activation_block,
        current_debt,
        0,
    ]
