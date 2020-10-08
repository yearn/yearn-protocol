import pytest
import brownie


def test_controller_deployment(gov, rewards, Controller):
    controller = gov.deploy(Controller, rewards)
    # Double check all the deployment variable values
    assert controller.governance() == gov
    assert controller.rewards() == rewards
    assert controller.onesplit() == "0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e"
    assert controller.split() == 500


@pytest.mark.parametrize(
    "getter,setter,val",
    [
        ("split", "setSplit", 1000),
        ("onesplit", "setOneSplit", None),
        ("governance", "setGovernance", None),
    ],
)
def test_controller_setParams(accounts, gov, rewards, getter, setter, val, Controller):
    if not val:
        # Can't access fixtures, so use None to mean an address literal
        val = accounts[1]

    controller = gov.deploy(Controller, rewards)

    # Only governance can set this param
    with brownie.reverts("!governance"):
        getattr(controller, setter)(val, {"from": accounts[1]})
    getattr(controller, setter)(val, {"from": gov})
    assert getattr(controller, getter)() == val

    # When changing governance contract, make sure previous no longer has access
    if getter == "governance":
        with brownie.reverts("!governance"):
            getattr(controller, setter)(val, {"from": gov})
