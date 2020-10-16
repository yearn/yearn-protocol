import pytest
import brownie

from brownie import Wei, convert, accounts

from brownie import (
    StrategyCreamCRV,
    Controller,
    yVault
)

MAX_LIMIT = 2 ** 256 -1

# CRV
TOKEN_CONTRACT = "0xD533a949740bb3306d119CC777fa900bA034cd52"

STRAT_NAME = "StrategyCreamCRV"

@pytest.fixture
def token(Contract):
    yield Contract.from_explorer(TOKEN_CONTRACT)

@pytest.fixture
def strategy(gov, controller):
    strategy = gov.deploy(StrategyCreamCRV, controller)
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