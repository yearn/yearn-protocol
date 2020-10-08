import pytest
import brownie


# Define the actual vault deployment test as a fixture so it can be reused
# across the specific vaults under test. All vaults are broken out into their
# own file so they can be parallelized with xdist.
@pytest.fixture
def check_vault_deployment():
    def actual_fixture(gov, token, controller, Vault):
        vault = gov.deploy(Vault, token, controller)
        # Addresses
        assert vault.governance() == gov
        assert vault.controller() == controller
        assert vault.token() == token
        # UI Stuff
        assert vault.name() == "yearn " + token.name()
        assert vault.symbol() == "y" + token.symbol()
        assert vault.decimals() == token.decimals()

    yield actual_fixture


# Setup the parameters to feed into the vault under test. For every tuple
# declared in the below params, a test will execute against a vault
# referencing this fixture.
@pytest.fixture(
    params=[
        ("min", "setMin", 9000),
        ("healthFactor", "setHealthFactor", 100),
        ("controller", "setController", None),
        ("governance", "setGovernance", None),
    ],
)
def vault_params(request):
    return request.param


# Define the actual vault test as a fixture so it can be reused across the
# specific vaults under test. All vaults are broken out into their own file
# so they can be parallelized with xdist.
@pytest.fixture
def check_vault_setParams():
    def actual_fixture(accounts, gov, token, controller, getter, setter, val, Vault):
        if not val:
            # Can't access fixtures, so use None to mean an address literal
            val = accounts[1]

        vault = gov.deploy(Vault, token, controller)

        if not hasattr(vault, getter):
            return  # Some combinations aren't valid

        # Only governance can set this param
        with brownie.reverts("!governance"):
            getattr(vault, setter)(val, {"from": accounts[1]})
        getattr(vault, setter)(val, {"from": gov})
        assert getattr(vault, getter)() == val

        # When changing governance contract, make sure previous no longer has access
        if getter == "governance":
            with brownie.reverts("!governance"):
                getattr(vault, setter)(val, {"from": gov})

    yield actual_fixture
