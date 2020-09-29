import pytest
import brownie


def test_strategy_config(web3, gov, token, vault, strategy, rando):

    token.transfer(vault, 100, {"from": gov})  # addStrategy requires tokens
    assert vault.strategies(strategy) == [False, 0, 0, 0, 0, 0, 0]

    with brownie.reverts():
        vault.addStrategy(strategy, 100, 1000, 10, {"from": rando})

    vault.addStrategy(strategy, 100, 1000, 10, {"from": gov})
    activation_block = web3.eth.blockNumber
    assert vault.strategies(strategy) == [
        True,
        activation_block,
        1000,
        10,
        activation_block,
        100,
        0,
    ]

    with brownie.reverts():
        vault.updateStrategy(strategy, 1500, 15, {"from": rando})

    vault.updateStrategy(strategy, 1500, 15, {"from": gov})
    assert vault.strategies(strategy) == [
        True,
        activation_block,
        1500,
        15,
        activation_block,
        100,
        0,
    ]

    with brownie.reverts():
        vault.revokeStrategy(strategy, {"from": rando})

    vault.revokeStrategy(strategy, {"from": gov})
    assert vault.strategies(strategy) == [
        True,
        activation_block,
        0,
        15,
        activation_block,
        100,
        0,
    ]
