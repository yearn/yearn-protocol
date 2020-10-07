import pytest


@pytest.fixture
def rewards(a):
    yield a[2]


@pytest.fixture
def gov(a):
    yield a[3]


@pytest.fixture
def token(a, Token):
    # Must be ERC20
    yield a[0].deploy(Token)


@pytest.fixture
def controller(a):
    yield a[4]


@pytest.fixture
def andre(accounts):
    return accounts.at("0x2D407dDb06311396fE14D4b49da5F0471447d45C", force=True)


@pytest.fixture
def ychad(accounts):
    return accounts.at("0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52", force=True)


@pytest.fixture
def binance(accounts):
    return accounts.at("0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE", force=True)
