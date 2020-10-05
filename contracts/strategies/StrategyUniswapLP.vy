# @version 0.2.4
from vyper.interfaces import ERC20

struct StrategyParams:
    activation: uint256  # Activation block.number
    debtLimit: uint256  # Maximum borrow amount
    rateLimit: uint256  # Increase/decrease per block
    lastSync: uint256  # block.number of the last time a sync occured
    totalDebt: uint256
    totalReturns: uint256


interface VaultAPI:
    def token() -> address: view
    def strategies(_strategy: address) -> StrategyParams: view
    def creditAvailable() -> (uint256): view
    def expectedReturn() -> (uint256): view
    def sync(_return: uint256): nonpayable
    def migrateStrategy(_newStrategy: address): nonpayable
    def revokeStrategy(): nonpayable


interface StrategyAPI:
    def keeper() -> address: view
    def tendTrigger(gasCost: uint256) -> bool: view
    def tend(): nonpayable
    def harvestTrigger(gasCost: uint256) -> bool: view
    def harvest(): nonpayable
    def vault() -> address: view


interface StakingRewards:
    def earned(account: address) -> uint256: view
    def balanceOf(account: address) -> uint256: view
    def stakingToken() -> address: view
    def rewardsToken() -> address: view
    def stake(amount: uint256): nonpayable
    def withdraw(amount: uint256): nonpayable
    def getReward(): nonpayable
    def exit(): nonpayable


interface UniswapWrapper:
    def swap(token_in: address, token_out: address, amount_in: uint256, min_amount_out: uint256, to: address) -> bool: nonpayable
    def quote(token_in: address, token_out: address, amount_in: uint256) -> uint256: view


interface UniswapPair:
    def balanceOf(owner: address) -> uint256: view
    def totalSupply() -> uint256: view
    def token0() -> address: view
    def token1() -> address: view
    def approve(spender: address, amount: uint256) -> bool: nonpayable
    def transfer(recipient: address, amount: uint256) -> bool: nonpayable
    def getReserves() -> (uint256, uint256, uint256): view
    def quote(amountA: uint256, reserveA: uint256, reserveB: uint256) -> uint256: view


interface UniswapRouter:
    def addLiquidity(
        tokenA: address,
        tokenB: address,
        amountADesired: uint256,
        amountBDesired: uint256,
        amountAMin: uint256,
        amountBMin: uint256,
        to: address,
        deadline: uint256
    ) -> (uint256, uint256, uint256): nonpayable


vault: public(VaultAPI)
strategist: public(address)
keeper: public(address)
governance: public(address)
pendingGovernance: public(address)
want: public(UniswapPair)
reserve: public(uint256)
emergencyExit: public(bool)
staking: public(StakingRewards)
uni_wrap: UniswapWrapper
uni_router: UniswapRouter
reward: ERC20
token0: ERC20
token1: ERC20


@external
def __init__(_vault: address, _governance: address, _staking: address):
    self.vault = VaultAPI(_vault)
    self.want = UniswapPair(self.vault.token())
    self.strategist = msg.sender
    self.keeper = msg.sender
    self.governance = _governance

    self.staking = StakingRewards(_staking)
    assert self.staking.stakingToken() == self.want.address, "!want"
    self.reward = ERC20(self.staking.rewardsToken())
    self.token0 = ERC20(self.want.token0())
    self.token1 = ERC20(self.want.token1())

    self.uni_wrap = UniswapWrapper(0xE929d7af8CEdA5D6002568110675B82D3fA84BA3)
    self.uni_router = UniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)

    self.want.approve(self.vault.address, MAX_UINT256)
    self.token0.approve(self.uni_router.address, MAX_UINT256)
    self.token1.approve(self.uni_router.address, MAX_UINT256)
    self.reward.approve(self.uni_wrap.address, MAX_UINT256)


@external
def setGovernance(_governance: address):
    assert msg.sender == self.governance, "!governance"
    self.pendingGovernance = _governance


@external
def acceptGovernance():
    assert msg.sender == self.pendingGovernance, "!governance"
    self.governance = self.pendingGovernance


@external
def setStrategist(_strategist: address):
    assert msg.sender in [self.strategist, self.governance], "!governance"
    self.strategist = _strategist


@external
def setKeeper(_keeper: address):
    assert msg.sender in [self.strategist, self.governance], "!governance"
    self.keeper = _keeper


@view
@external
def expectedReturn() -> uint256:
    earned: uint256 = self.staking.earned(self)
    amount0: uint256 = self.uni_wrap.quote(self.reward.address, self.token0.address, earned / 2)
    amount1: uint256 = self.uni_wrap.quote(self.reward.address, self.token1.address, earned / 2)

    reserve0: uint256 = 0
    reserve1: uint256 = 0
    ts: uint256 = 0
    reserve0, reserve1, ts = self.want.getReserves()
    supply: uint256 = self.want.totalSupply()

    liquidity: uint256 = min(
        amount0 * supply / reserve0,
        amount1 * supply / reserve1,
    )
    return liquidity


@internal
def prepareReturn():
    self.staking.getReward()
    self.uni_wrap.swap(
        self.reward.address,
        self.token0.address,
        self.reward.balanceOf(self) / 2,
        0,
        self
    )
    self.uni_wrap.swap(
        self.reward.address,
        self.token1.address,
        self.reward.balanceOf(self),
        0,
        self
    )


@internal
def adjustPosition():
    self.uni_router.addLiquidity(
        self.token0.address,
        self.token1.address,
        self.token0.balanceOf(self),
        self.token1.balanceOf(self),
        0,
        0,
        self,
        block.timestamp
    )
    self.staking.stake(self.want.balanceOf(self))


@internal
def exitPosition():
    self.staking.exit()
    self.prepareReturn()


@view
@external
def tendTrigger(gasCost: uint256) -> bool:
    return False


@external
def tend():
    assert msg.sender in [self.keeper, self.strategist, self.governance]
    self.adjustPosition()


@view
@external
def harvestTrigger(gasCost: uint256) -> bool:
    return ERC20(self.want.address).balanceOf(self) > 0


@external
def harvest():
    assert msg.sender in [self.keeper, self.strategist, self.governance]

    if self.emergencyExit:
        self.exitPosition()
    else:
        self.prepareReturn()

    self.reserve = max(self.reserve, self.want.balanceOf(self))

    self.vault.sync(self.want.balanceOf(self) - self.reserve)

    self.adjustPosition()


@external
def migrate(_newStrategy: address):
    assert msg.sender in [self.strategist, self.governance]
    assert StrategyAPI(_newStrategy).vault() == self.vault.address
    self.exitPosition()
    self.want.transfer(_newStrategy, self.want.balanceOf(self))
    self.vault.migrateStrategy(_newStrategy)


@external
def setEmergencyExit():
    assert msg.sender in [self.strategist, self.governance]
    self.emergencyExit = True
    self.exitPosition()
    self.vault.revokeStrategy()
    self.reserve = max(self.reserve, self.want.balanceOf(self))
    self.vault.sync(self.want.balanceOf(self) - self.reserve)


@external
def sweep(_token: address):
    assert _token != self.want.address, "!want"
    ERC20(_token).transfer(self.governance, ERC20(_token).balanceOf(self))
