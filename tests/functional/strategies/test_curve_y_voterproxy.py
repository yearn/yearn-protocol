import pytest
import brownie

from brownie import StrategyCurveYVoterProxy

STRATEGIES = [StrategyCurveYVoterProxy]


@pytest.mark.parametrize("Strategy", STRATEGIES)
def test_strategy_deployment(gov, controller, Strategy, check_strategy_deployment):
    check_strategy_deployment(gov, controller, Strategy)


@pytest.mark.parametrize("Strategy", STRATEGIES)
def test_strategy_setParams(
    accounts, gov, controller, Strategy, strategy_params, check_strategy_setParams
):
    getter = strategy_params[0]
    setter = strategy_params[1]
    val = strategy_params[2]
    check_strategy_setParams(accounts, gov, controller, getter, setter, val, Strategy)
