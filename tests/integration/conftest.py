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
from brownie.exceptions import VirtualMachineError

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


@pytest.fixture(params=STRATEGIES, ids=[s._name for s in STRATEGIES])
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


@pytest.fixture(scope="module", autouse=True)
def uniswap(Contract):
    yield Contract.from_explorer("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")


@pytest.fixture(scope="module", autouse=True)
def weth(Contract):
    yield Contract.from_explorer("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2")


def sweep_holdings(target, accounts, token=None):
    if token:
        transfer = lambda a: token.transfer(target, token.balanceOf(a), {"from": a})
        balance = lambda: token.balanceOf(target)
        total_supply = token.totalSupply()
        symbol = token.symbol()
    else:
        # NOTE: Save some ETH for gas costs
        transfer = lambda a: a.transfer(target, a.balance() - 10 ** 18)
        balance = lambda: target.balance()
        total_supply = 130_000_000 * 10 ** 18
        symbol = "ETH"

    for a in accounts:
        transfer(a)

    target_share = 100 * balance() / total_supply
    print(f"Andre has {target_share:0.2f}% of {symbol}")


@pytest.fixture(scope="module", autouse=True)
def andre(accounts, weth, uniswap, Token, Contract):
    andre = accounts[-1]  # Andre hacked Binance
    secondary_wallets = accounts[-6:-1]
    # Sweep all ETH
    sweep_holdings(andre, secondary_wallets)

    for Strategy in STRATEGIES:
        strategy = andre.deploy(Strategy, accounts[1])
        token = Token.at(strategy.want())
        print(f"Strategy {strategy.getName()} wants {token.symbol()}")

        # Option 0: Andre has a ton of ETH, which can be wrapped to WETH
        # NOTE: Only wrap 1/4 of holdings as WETH (save some for Uniswap)
        if token.address == weth.address:
            weth.deposit({"from": andre, "value": andre.balance() // 4})
            continue

        # Option 1: Andre has enough tokens, we're done
        sweep_holdings(andre, secondary_wallets, token)
        if token.balanceOf(andre) >= token.totalSupply() // 50:
            continue  # Now we have enough tokens!

        # Option 2: If Andre doesn't have enough tokens, but UniSwap lists it with enough liquidity
        # NOTE: Uniswap must have at least 2% of the supply so we don't fail because of slippage
        if token.balanceOf(uniswap) >= token.totalSupply() // 50:
            values = uniswap.getAmountsIn(
                token.totalSupply() // 100,  # 1% of total supply
                [weth, token],  # Path routing to token
            )
            uniswap.swapETHForExactTokens(
                token.totalSupply() // 100,  # 1% of total supply
                [weth, token],  # Path routing to token
                andre,  # Receiver
                2 ** 32 - 1,  # Deadline (far in the future)
                {
                    "from": andre,
                    # First amount is amount to send (1 WETH = 1 ETH)
                    "value": values[0],
                },
            )
            continue  # Now we have enough token!

        # Option 3: Become a Curve Pool LP
        # If all else fails, it's probably because the strategy is for a Curve pool
        # So, as a shortcut, we should just become an LP to get those tokens
        if hasattr(strategy, "curve"):
            curve = Contract.from_explorer(strategy.curve())
            balances = []
            for i in range(4):
                try:
                    c = Contract.from_explorer(curve.coins(i))
                except VirtualMachineError:
                    break  # Pool only has 3 coins

                # If we don't have enough tokens, and it's a y-token, deposit to get more
                sweep_holdings(andre, secondary_wallets, c)
                if (
                    c.balanceOf(andre) < c.balanceOf(curve) // 50
                    and c.symbol()[0] == "y"
                    and hasattr(c, "token")
                    and hasattr(c, "deposit")
                ):
                    underlying = Token.at(c.token())
                    sweep_holdings(andre, secondary_wallets, underlying)
                    # NOTE: Only deposit 1/3 of our tokens into y-Vaults
                    if underlying.balanceOf(andre) > 0:
                        underlying.approve(
                            c, underlying.balanceOf(andre), {"from": andre}
                        )
                        c.deposit(underlying.balanceOf(andre) // 3, {"from": andre})

                if c.balanceOf(andre) > 0:
                    # Deposit enough so that it's less than 2% of the pool
                    # NOTE: Only deposit half of our tokens into Curve
                    balances.append(
                        min(c.balanceOf(andre) // 2, c.balanceOf(curve) // 50)
                    )

                    # Approve Curve to trade for LP tokens
                    c.approve(curve, c.balanceOf(andre), {"from": andre})
                else:
                    balances.append(0)

            assert any(balances), "Andre doesn't have any of the underlying tokens!"
            curve.add_liquidity(balances, 0, {"from": andre})
            continue  # Now we have LP tokens!

        assert token.balanceOf(andre) / token.totalSupply() >= 0.01  # 1% of supply

    return andre


@pytest.fixture
def minnow(accounts, andre, token):
    """Naive actor with little capital"""
    a = accounts[1]
    andre.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(andre) // 1000  # 0.1% of what Andre has
    token.transfer(a, amt, {"from": andre})
    yield a


@pytest.fixture
def dolphin(accounts, andre, token):
    """Playful actor with a decent amount of capital"""
    a = accounts[2]
    andre.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(andre) // 100  # 1% of what Andre has
    token.transfer(a, amt, {"from": andre})
    yield a


@pytest.fixture
def shark(accounts, andre, token):
    """Ruthless actor with a fair amount of capital"""
    a = accounts[3]
    andre.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(andre) // 10  # 10% of what Andre has
    token.transfer(a, amt, {"from": andre})
    yield a


@pytest.fixture
def whale(accounts, andre, token):
    """Careless actor with lots of capital"""
    a = accounts[4]
    andre.transfer(a, 10 ** 18)  # Give them 1 ETH for gas
    amt = token.balanceOf(andre)  # 100% of what Andre has
    token.transfer(a, amt, {"from": andre})
    yield a
