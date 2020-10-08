import pytest
import brownie


# Define the actual strategy deployment test as a fixture so it can be reused
# across the specific strategies under test. All strategies are broken out into
# their own file so they can be parallelized with xdist.
@pytest.fixture
def check_strategy_deployment():
    def actual_fixture(gov, controller, Strategy):
        strategy = gov.deploy(Strategy, controller)
        # Double check all the deployment variable values
        assert strategy.governance() == gov
        assert strategy.controller() == controller
        assert strategy.getName() == Strategy._name

    yield actual_fixture


# Setup the parameters to feed into the strategy under test. For every tuple
# declared in the below params, a test will execute against a strategy
# referencing this fixture.
@pytest.fixture(
    params=[
        ("governance", "setGovernance", None),
        ("controller", "setController", None),
        ("strategist", "setStrategist", None),
        ("fee", "setFee", 100),
        ("withdrawalFee", "setWithdrawalFee", 100),
        ("performanceFee", "setPerformanceFee", 1000),
    ],
)
def strategy_params(request):
    return request.param


# Define the actual strategy test as a fixture so it can be reused across the
# specific strategies under test. All strategies are broken out into their own
# file so they can be parallelized with xdist.
@pytest.fixture
def check_strategy_setParams():
    def actual_fixture(accounts, gov, controller, getter, setter, val, Strategy):
        if not val:
            # Can't access fixtures, so use None to mean an address literal
            val = accounts[1]

        strategy = gov.deploy(Strategy, controller)

        if not hasattr(strategy, getter):
            return  # Some combinations aren't valid

        # Only governance can set this param
        with brownie.reverts("!governance"):
            getattr(strategy, setter)(val, {"from": accounts[1]})
        getattr(strategy, setter)(val, {"from": gov})
        assert getattr(strategy, getter)() == val

        # When changing governance contract, make sure previous no longer has access
        if getter == "governance":
            with brownie.reverts("!governance"):
                getattr(strategy, setter)(val, {"from": gov})

    yield actual_fixture
