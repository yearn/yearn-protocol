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


def test_earn(chain, whale, token, vault, strategy, strategist):
    # YOLO all in like a real whale
    starting_balance = token.balanceOf(whale)
    token.approve(vault, starting_balance, {"from": whale})
    vault.depositAll({"from": whale})

    if hasattr(strategy, "harvest"):
        update_strategy = lambda: strategy.harvest({"from": strategist})
    elif hasattr(strategy, "skim"):
        update_strategy = lambda: strategy.skim({"from": strategist})
    else:
        raise AssertionError(f"Strategy {strategy.getName()} does not have an action!")

    # Do some strategy action...
    update_strategy()
    chain.mine(200)  # mine 200 blocks
    chain.sleep(200 * 15)  # sleep 200 blocks worth of time
    # Do it again...
    update_strategy()

    # Shouldn't lose any money since no one else is interacting with the chain
    vault.withdrawAll({"from": whale})
    assert token.balanceOf(whale) - starting_balance >= 0
