def test_deposit_withdraw(vault, token, whale):
    balance = token.balanceOf(whale)
    token.approve(vault, balance, {"from": whale})
    vault.deposit(balance, {"from": whale})
    assert vault.totalSupply() == token.balanceOf(vault) == balance
    assert vault.borrowed() == 0
    assert vault.pricePerShare() == 10 ** token.decimals()  # 1:1 price
    vault.withdraw(vault.balanceOf(whale), {"from": whale})
    assert vault.totalSupply() == token.balanceOf(vault) == 0
    assert vault.borrowed() == 0
    assert token.balanceOf(whale) == balance
