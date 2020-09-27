import pytest


@pytest.fixture
def andre(accounts):
    # Has all the tokens
    yield accounts[0]


@pytest.fixture
def token(andre, Token):
    yield andre.deploy(Token)


@pytest.fixture
def gov(accounts):
    yield accounts[1]


@pytest.fixture
def guardian(accounts):
    yield accounts[2]


@pytest.fixture
def vault(gov, guardian, token, Vault):
    yield guardian.deploy(Vault, token, gov)


@pytest.fixture
def strategist(accounts):
    yield accounts[3]


@pytest.fixture
def keeper(accounts):
    yield accounts[4]


@pytest.fixture
def strategy(gov, strategist, keeper, vault, TestStrategy):
    strategy = strategist.deploy(TestStrategy, vault, gov)
    strategy.setKeeper(keeper)
    yield strategy


@pytest.fixture
def pleb(accounts):
    # Has no tokens
    yield accounts[5]


@pytest.fixture
def minnow(accounts, andre, token):
    a = accounts[6]
    # Has 0.01% of tokens
    token.transfer(a, token.totalSupply() // 10000, {"from": andre})
    yield a


@pytest.fixture
def dolphin(accounts, andre, token):
    a = accounts[7]
    # Has 0.1% of tokens
    token.transfer(a, token.totalSupply() // 1000, {"from": andre})
    yield a


@pytest.fixture
def shark(accounts, andre, token):
    a = accounts[8]
    # Has 1% of tokens
    token.transfer(a, token.totalSupply() // 100, {"from": andre})
    yield a


@pytest.fixture
def whale(accounts, andre, token):
    a = accounts[9]
    # Has 10% of tokens
    token.transfer(a, token.totalSupply() // 10, {"from": andre})
    yield a
