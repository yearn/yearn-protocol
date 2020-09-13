import pytest


from brownie import (
    StrategyCreamYFI,
    StrategyCurveSBTC,
    StrategyCurveYBUSD,
    StrategyCurveYCRVVoter,
    StrategyDAICurve,
    StrategyDForceUSDC,
    StrategyDForceUSDT,
    StrategyMKRVaultDAIDelegate,
    StrategyTUSDCurve,
    StrategyVaultUSDC,
)

STRATEGIES = [
    StrategyCreamYFI,
    StrategyCurveSBTC,
    StrategyCurveYBUSD,
    StrategyCurveYCRVVoter,
    StrategyDAICurve,
    StrategyDForceUSDC,
    StrategyDForceUSDT,
    StrategyMKRVaultDAIDelegate,
    StrategyTUSDCurve,
    StrategyVaultUSDC,
]


@pytest.fixture
def gov(accounts):
    # Normally this is a contract, but just use an address for testing
    yield accounts[9]


@pytest.fixture
def rewards(accounts):
    # Normally this is a contract, but just use an address for testing
    yield accounts[8]


@pytest.fixture
def controller(rewards, gov, Controller):
    yield gov.deploy(Controller, rewards)


@pytest.fixture(params=STRATEGIES)
def strategy(gov, controller, request):
    yield gov.deploy(request.param, controller)


@pytest.fixture
def token(Contract, Token, strategy):
    # The token that each vault holds is whatever the strategy wants
    if strategy.want() == "0x0000000000085d4780B73119b644AE5ecd22b376":
        # TrueUSD is a proxy, return an ERC20 wrapper instead of fetching it
        # TODO: Brownie should actually handle this case, debug why not
        yield Token.at(strategy.want())
    else:
        yield Contract.from_explorer(strategy.want())


@pytest.fixture
def vault(gov, token, controller, strategy, yVault):
    vault = gov.deploy(yVault, token, controller)
    controller.setVault(token, vault, {"from": gov})
    controller.approveStrategy(token, strategy, {"from": gov})
    controller.setStrategy(token, strategy, {"from": gov})
    yield vault


@pytest.fixture
def delegated_vault(gov, token, controller, strategy, yDelegatedVault):
    vault = gov.deploy(yDelegatedVault, token, controller)
    controller.setVault(token, vault, {"from": gov})
    controller.setStrategy(token, strategy, {"from": gov})
    yield vault


@pytest.fixture(scope="session")
def uniswap(Contract):
    yield Contract.from_explorer("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")


@pytest.fixture(scope="session")
def weth(Contract):
    yield Contract.from_explorer("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")


@pytest.fixture
def binance(accounts, token, weth, uniswap):
    binance = accounts[-1]
    # Binance has many of the tokens, but not all of them
    if token.balanceOf(binance) <= token.totalSupply() // 100:
        # But it could swap for the rest
        values = uniswap.getAmountsIn(
            token.totalSupply() // 100,  # 1% of total supply
            [weth, token],  # Path routing to token
        )
        uniswap.swapETHForExactTokens(
            token.totalSupply() // 100,  # 1% of total supply
            [weth, token],  # Path routing to token
            binance,  # Receiver
            2 ** 32 - 1,  # Deadline (far in the future)
            {
                "from": binance,
                "value": values[0],  # First amount is amount to send (1 WETH = 1 ETH)
            },
        )
    yield binance


@pytest.fixture
def minnow(accounts, binance, token):
    """Naive actor with little capital"""
    a = accounts[1]
    binance.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(binance) // 1000  # 0.1% of what Binance has
    token.transfer(a, amt, {"from": binance})
    yield a


@pytest.fixture
def dolphin(accounts, binance, token):
    """Playful actor with a decent amount of capital"""
    a = accounts[2]
    binance.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(binance) // 100  # 1% of what Binance has
    token.transfer(a, amt, {"from": binance})
    yield a


@pytest.fixture
def shark(accounts, binance, token):
    """Ruthless actor with a fair amount of capital"""
    a = accounts[3]
    binance.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(binance) // 10  # 10% of what Binance has
    token.transfer(a, amt, {"from": binance})
    yield a


@pytest.fixture
def whale(accounts, binance, token):
    """Careless actor with lots of capital"""
    a = accounts[4]
    binance.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(binance)  # 100% of what Binance has
    token.transfer(a, amt, {"from": binance})
    yield a
