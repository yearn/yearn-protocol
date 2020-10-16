import pytest
import brownie

from brownie import Wei, convert, accounts

from brownie import (
    StrategyCreamUNI,
    Controller,
    yVault
)

MAX_LIMIT = 2 ** 256 -1

# UNI
TOKEN_CONTRACT = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"

STRAT_NAME = "StrategyCreamUNI"

@pytest.fixture
def token(Contract):
    yield Contract.from_explorer(TOKEN_CONTRACT)

@pytest.fixture
def strategy(gov, controller):
    strategy = gov.deploy(StrategyCreamUNI, controller)
    return strategy

@pytest.fixture
def vault(gov, controller, strategy, token):
    vault = gov.deploy(yVault, token, controller)
    vault.setMin(10000)
    return vault

def test_deployment(strategy, vault, token, gov, controller):
    # check strat values
    assert strategy.governance() == gov
    assert strategy.controller() == controller
    assert strategy.getName() == STRAT_NAME

    # check vault values
    assert vault.governance() == gov
    assert vault.controller() == controller
    assert vault.token() == token
    assert vault.name() == "yearn " + token.name()
    assert vault.symbol() == "y" + token.symbol()
    assert vault.decimals() == token.decimals()


def max_approve(token, address, from_account):
    token.approve(address, MAX_LIMIT, {'from': from_account})