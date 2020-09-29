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
    assert token.balanceOf(vault) == token.balanceOf(gov)
    assert vault.totalDebt() == 0  # No connected strategies yet
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
        strategy,
        token.totalSupply(),  # Debt limit of 100% of token supply
        token.totalSupply() // 1000,  # Rate limt of 0.1% of token supply per block
        {"from": gov},
    )
    # Call this once to seed the strategy with debt
    strategy.harvest({"from": strategist})
    assert token.balanceOf(strategy) > 0
    assert (
        token.balanceOf(strategy)
        == vault.totalDebt()
        == vault.strategies(strategy)[4]  # totalDebt
    )
    yield strategy


@pytest.fixture
def rando(accounts):
    yield accounts[9]
