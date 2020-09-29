import pytest
import brownie


@pytest.fixture
def vault(gov, token, Vault):
    yield gov.deploy(Vault, token, gov, gov)


def test_transfer(accounts, token, vault):
    a, b, c = accounts[0:3]
    token.approve(vault, token.balanceOf(a), {"from": a})
    vault.deposit(token.balanceOf(a), {"from": a})

    assert vault.balanceOf(a) == token.balanceOf(vault)
    assert vault.balanceOf(b) == 0

    vault.transfer(b, vault.balanceOf(a), {"from": a})

    assert vault.balanceOf(a) == 0
    assert vault.balanceOf(b) == token.balanceOf(vault)

    vault.approve(c, vault.balanceOf(b), {"from": b})
    with brownie.reverts():
        vault.transferFrom(b, a, vault.balanceOf(b), {"from": a})
    vault.transferFrom(b, a, vault.balanceOf(b), {"from": c})

    assert vault.balanceOf(a) == token.balanceOf(vault)
    assert vault.balanceOf(b) == 0
