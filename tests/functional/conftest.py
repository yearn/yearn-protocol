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
    vault = guardian.deploy(Vault, token, gov, rewards)
    vault.setDebtLimit(token.totalSupply(), {"from": gov})
    # Make it so vault has some AUM to start
    token.approve(vault, token.balanceOf(gov) // 2, {"from": gov})
    vault.deposit(token.balanceOf(gov) // 2, {"from": gov})
    yield vault


@pytest.fixture
def strategist(accounts):
    yield accounts[3]


@pytest.fixture
def keeper(accounts):
    yield accounts[4]


@pytest.fixture
def strategy(gov, strategist, token, vault, TestStrategy):
    strategy = strategist.deploy(TestStrategy, vault, gov)
    vault.addStrategy(
        strategy, token.balanceOf(vault), token.totalSupply(), 1, {"from": gov}
    )
    # Make it so strategy has "earned" something
    token.transfer(strategy, token.balanceOf(gov), {"from": gov})
    yield strategy


@pytest.fixture
def rando(accounts):
    yield accounts[9]
