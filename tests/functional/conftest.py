import pytest


@pytest.fixture
def gov(accounts):
    yield accounts[0]


@pytest.fixture
def token(gov, Token):
    yield gov.deploy(Token)
