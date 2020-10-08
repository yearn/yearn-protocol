import pytest


@pytest.fixture(scope="module", autouse=True)
def shared_setup(module_isolation):
    pass


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
