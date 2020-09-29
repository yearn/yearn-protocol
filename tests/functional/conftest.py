import pytest


@pytest.fixture
def gov(accounts):
    yield accounts[0]


@pytest.fixture
def rewards(accounts):
    yield accounts[1]


@pytest.fixture
def guardian(accounts):
    yield accounts[2]


@pytest.fixture
def token(gov, Token):
    yield gov.deploy(Token)


@pytest.fixture
def vault(gov, guardian, token, rewards, Vault):
    yield guardian.deploy(Vault, token, gov, rewards)


@pytest.fixture
def strategist(accounts):
    yield accounts[3]


@pytest.fixture
def keeper(accounts):
    yield accounts[4]


@pytest.fixture
def strategy(gov, strategist, vault, TestStrategy):
    yield strategist.deploy(TestStrategy, vault, gov)


@pytest.fixture
def rando(accounts):
    yield accounts[9]
