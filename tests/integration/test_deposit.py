def test_deposit_shares(minnow, token, vault):
    balance = token.balanceOf(minnow)
    token.approve(vault, balance, {"from": minnow})
    vault.deposit(balance, {"from": minnow})
    assert vault.balanceOf(minnow) == balance * vault.totalSupply() // vault.balance()
