import pytest
import brownie


from brownie import (
    StrategyCreamYFI,
    StrategyCurveBTCVoterProxy,
    StrategyCurveBUSDVoterProxy,
    StrategyCurveYVoterProxy,
    StrategyCurve3CrvVoterProxy,
    StrategyDAICurve,
    StrategyDForceUSDC,
    StrategyDForceUSDT,
    StrategyMKRVaultDAIDelegate,
    StrategyTUSDCurve,
    StrategyVaultUSDC,
)

STRATEGIES = [
    StrategyCreamYFI,
    StrategyCurveBTCVoterProxy,
    StrategyCurveBUSDVoterProxy,
    StrategyCurveYVoterProxy,
    StrategyCurve3CrvVoterProxy,
    StrategyDAICurve,
    StrategyDForceUSDC,
    StrategyDForceUSDT,
    StrategyMKRVaultDAIDelegate,
    StrategyTUSDCurve,
    StrategyVaultUSDC,
]


@pytest.mark.parametrize("Strategy", STRATEGIES)
def test_strategy_deployment(gov, controller, Strategy):
    strategy = gov.deploy(Strategy, controller)
    # Double check all the deployment variable values
    assert strategy.governance() == gov
    assert strategy.controller() == controller
    assert strategy.getName() == Strategy._name


@pytest.mark.parametrize(
    "getter,setter,val",
    [
        ("governance", "setGovernance", None),
        ("controller", "setController", None),
        ("strategist", "setStrategist", None),
        ("fee", "setFee", 100),
        ("withdrawalFee", "setWithdrawalFee", 100),
        ("performanceFee", "setPerformanceFee", 1000),
    ],
)
@pytest.mark.parametrize("Strategy", STRATEGIES)
def test_strategy_setParams(accounts, gov, controller, getter, setter, val, Strategy):
    if not val:
        # Can't access fixtures, so use None to mean an address literal
        val = accounts[1]

    strategy = gov.deploy(Strategy, controller)

    if not hasattr(strategy, getter):
        return  # Some combinations aren't valid

    # Only governance can set this param
    with brownie.reverts():
        getattr(strategy, setter)(val, {"from": accounts[1]})
    getattr(strategy, setter)(val, {"from": gov})
    assert getattr(strategy, getter)() == val

    # When changing governance contract, make sure previous no longer has access
    if getter == "governance":
        with brownie.reverts("!governance"):
            getattr(strategy, setter)(val, {"from": gov})
