import pytest
import brownie


@pytest.fixture
def vault(gov, token, Vault):
    # NOTE: Overriding the one in conftest because it has values already
    yield gov.deploy(Vault, token, gov, gov)


def test_transfer(accounts, token, vault, fn_isolation):
    a, b = accounts[0:2]
    token.approve(vault, token.balanceOf(a), {"from": a})
    vault.deposit(token.balanceOf(a), {"from": a})

    assert vault.balanceOf(a) == token.balanceOf(vault)
    assert vault.balanceOf(b) == 0

    vault.transfer(b, vault.balanceOf(a), {"from": a})

    assert vault.balanceOf(a) == 0
    assert vault.balanceOf(b) == token.balanceOf(vault)


def test_transferFrom(accounts, token, vault, fn_isolation):
    a, b, c = accounts[0:3]
    token.approve(vault, token.balanceOf(a), {"from": a})
    vault.deposit(token.balanceOf(a), {"from": a})

    # Unapproved can't send
    with brownie.reverts():
        vault.transferFrom(b, a, vault.balanceOf(b) // 2, {"from": c})

    vault.approve(c, vault.balanceOf(b) // 2, {"from": b})
    assert vault.allowance(b, c) == vault.balanceOf(b) // 2

    # Can't send more than what is approved
    with brownie.reverts():
        vault.transferFrom(b, a, vault.balanceOf(b), {"from": c})

    assert vault.balanceOf(a) == token.balanceOf(vault)
    assert vault.balanceOf(b) == 0

    vault.transferFrom(b, a, vault.balanceOf(b) // 2, {"from": c})

    assert vault.balanceOf(a) == token.balanceOf(vault) // 2
    assert vault.balanceOf(b) == token.balanceOf(vault) // 2

    # If approval is unlimited, little bit of a gas savings
    vault.approve(c, 2 ** 256 - 1, {"from": b})
    vault.transferFrom(b, a, vault.balanceOf(b), {"from": c})

    assert vault.balanceOf(a) == token.balanceOf(vault)
    assert vault.balanceOf(b) == 0
