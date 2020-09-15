import brownie


def test_deposit_withdraw_shares(minnow, token, vault):
    balance = token.balanceOf(minnow)
    assert vault.balanceOf(minnow) == 0

    # Don't forget the approval
    with brownie.reverts():
        vault.deposit(balance // 3, {"from": minnow})
    token.approve(vault, balance, {"from": minnow})

    # Deposit 1/3 of entire balance
    vault.deposit(balance // 3, {"from": minnow})  # 1/3
    # Shares show appropiate balance
    assert (
        vault.balanceOf(minnow)
        == (balance // 3) * vault.totalSupply() // vault.balance()
    )

    # Deposit entire balance
    vault.depositAll({"from": minnow})  # 2/3
    # Shares show appropiate balance
    assert vault.balanceOf(minnow) == balance * vault.totalSupply() // vault.balance()

    # Withdraw 1/3 of entire balance
    vault.withdraw(vault.balanceOf(minnow) // 3, {"from": minnow})  # 1/3
    # Shares show appropiate balance (Might be a little off)
    assert (
        abs(
            vault.balanceOf(minnow)
            - 2 * (balance // 3) * vault.totalSupply() // vault.balance()
        )
        < 10  # This is fine, less than 1e-17 difference
    )

    # Withdraw entire balance
    vault.withdrawAll({"from": minnow})  # 2/3
    # Shares show appropiate balance
    assert vault.balanceOf(minnow) == 0
