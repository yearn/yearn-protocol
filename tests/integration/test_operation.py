class NormalOperation:
    def __init__(self, token, vault, gov, mint, user, keeper, TestStrategy):
        self.token = token
        self.vault = vault
        self.gov = gov
        self.mint = mint
        self.user = user
        self.keeper = keeper
        self.strategy_template = TestStrategy

    def setup(self):
        # Make sure at least one strategy is in the queue
        strategy = self.keeper.deploy(self.strategy_template, self.vault, self.gov)
        self.vault.addStrategy(
            strategy,
            self.token.balanceOf(self.vault) // 10,  # Start w/ 10% of Vault AUM
            self.token.balanceOf(self.vault) // 2,  # Go up to 50% of Vault AUM
            3,  # Fade in over 3 blocks
            {"from": self.gov},
        )
        self.strategies = [strategy]
        self.last_price = 1.0

    def rule_harvest(self):
        strategy = self.strategies[-1]
        strategy.harvest({"from": self.keeper})
        amt = self.token.balanceOf(strategy) // 1000  # 0.1% return, every time
        self.token.transfer(strategy, amt, {"from": self.mint})
        print(f"Available ({strategy}): {self.vault.availableForStrategy(strategy)}")

    def invariant_accounting(self):
        assert self.vault.borrowed() == sum(
            [self.token.balanceOf(s) for s in self.strategies]
        )

    def invariant_numbergoup(self):
        # Positive-return Strategy should never reduce the price of a share
        price = self.vault.pricePerShare() / 10 ** self.vault.decimals()
        assert price >= self.last_price
        self.last_price = price


def test_normal_operation(
    gov, vault, token, andre, whale, minnow, keeper, TestStrategy, state_machine,
):
    token.approve(vault, 2 ** 256 - 1, {"from": whale})
    vault.deposit(token.balanceOf(whale), {"from": whale})
    token.approve(vault, 2 ** 256 - 1, {"from": minnow})
    vault.deposit(token.balanceOf(minnow), {"from": minnow})
    state_machine(
        NormalOperation, token, vault, gov, andre, minnow, keeper, TestStrategy
    )
