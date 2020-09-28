#@version 0.2.4

# TODO: Add ETH Configuration
# TODO: Add Delegated Configuration
from vyper.interfaces import ERC20

implements: ERC20

interface DetailedERC20:
    def name() -> String[42]: view
    def symbol() -> String[20]: view
    def decimals() -> uint256: view

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

token: public(ERC20)
governance: public(address)
guardian: public(address)
pendingGovernance: address

struct StrategyParams:
    active: bool
    blockAdded: uint256
    starting: decimal
    debtLimit: uint256
    blockGain: decimal
    borrowed: uint256
    returns: uint256

event StrategyUpdate:
    strategy: indexed(address)
    returnAdded: uint256
    debtAdded: uint256
    totalReturn: uint256
    totalBorrowed: uint256

borrowed: public(uint256)  # Amount of tokens that all strategies have borrowed
# NOTE: Track the total for overhead targeting purposes
strategies: public(HashMap[address, StrategyParams])
emergencyShutdown: public(bool)

rewards: public(address)
managementFee: public(uint256)
MANAGEMENT_FEE_MAX: constant(uint256) = 10000

@external
def __init__(_token: address, _governance: address, _rewards: address):
    # TODO: Non-detailed Configuration?
    self.token = ERC20(_token)
    self.name = concat("yearn ", DetailedERC20(_token).name())
    self.symbol = concat("y", DetailedERC20(_token).symbol())
    self.decimals = DetailedERC20(_token).decimals()
    self.governance = _governance
    self.rewards = _rewards
    self.guardian = msg.sender
    self.managementFee = 500  # 5%


# 2-phase commit for a change in governance
@external
def setGovernance(_governance: address):
    assert msg.sender == self.governance
    self.pendingGovernance = _governance


@external
def acceptGovernance():
    assert msg.sender == self.pendingGovernance
    self.governance = msg.sender


@external
def setRewards(_rewards: address):
    assert msg.sender == self.governance
    self.rewards = _rewards


@external
def setManagementFee(_fee: uint256):
    assert msg.sender == self.governance
    self.managementFee = _fee


@external
def setGuardian(_guardian: address):
    assert msg.sender in [self.guardian, self.governance]
    self.guardian = _guardian


@external
def setEmergencyShutdown(_active: bool):
    """
    Activates Vault mode where all Strategies go into full withdrawal
    """
    assert msg.sender in [self.guardian, self.governance]
    self.emergencyShutdown = _active


@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    if self.allowance[_from][msg.sender] < MAX_UINT256:  # Unlimited approval (saves an SSTORE)
       self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def deposit(_amount: uint256):
    # Get new collateral
    reserve: uint256 = self.token.balanceOf(self)
    self.token.transferFrom(msg.sender, self, _amount)
    # TODO: `Deflationary` configuration only
    assert self.token.balanceOf(self) - reserve == _amount  # Deflationary token check

    # Mint new shares
    shares: uint256 = 0
    if self.totalSupply > 0:
        # Mint amount of shares based on what the Vault has overall
        shares = (_amount * self.totalSupply) / (self.borrowed + reserve)
    else:
        # No existing shares, so mint 1:1
        shares = _amount
    self.totalSupply += shares
    self.balanceOf[msg.sender] += shares
    log Transfer(ZERO_ADDRESS, msg.sender, shares)


@view
@internal
def _shareValue(_shares: uint256) -> uint256:
    return (_shares * (self.token.balanceOf(self) + self.borrowed)) / self.totalSupply


@external
def withdraw(_shares: uint256):
    # Calculate underlying value of shares (How much the shares are worth)
    value: uint256 = self._shareValue(_shares)
    # TODO: Should we limit withdrawal size to the proportional amount of "free"
    #       reserve as the user's share of whole would dicate? This would prevent
    #       "bank run" behavior by rate limiting withdrawals (in a way) during
    #       larger outflow events such as Vault upgrade or Emergency Shutdown
    # Adjust by ratio of reserves:total
    #value *= self.token.balanceOf(self)
    #value /= self.token.balanceOf(self) + self.borrowed
    # Then: delete `reserve` section below

    # Burn shares
    self.totalSupply -= value
    self.balanceOf[msg.sender] -= value
    log Transfer(msg.sender, ZERO_ADDRESS, value)

    reserve: uint256 = self.token.balanceOf(self)
    if value > reserve:
        deficit: uint256 = value - reserve
        # TODO: Obtain deficit from strategies... somehow
        #       But wait, if strategies don't have free capital then unwinding
        #       may be painful and trigger losses. Isn't it better to let just
        #       the `reserve` be available for withdrawals?
        #       If we maintain a reserve ratio (inversely proportional to risk)
        #       then withdrawals will be capped, "but unwinding" of strategies
        #       would happen more gracefully as the `available` amount for the
        #       strategy would decrease w/ the overall lower total collateral.
        #       Withdrawing a little bit at a time (pulling from reserves) is
        #       "safer" than pulling a lot all at once, and is more natural to
        #       outside observers who will build an expectation of their "free"
        #       capital being locked up in the system above and beyond the reserve


    # Withdraw balance (NOTE: fails currently if value > reserve)
    fee: uint256 = (value * self.managementFee) / MANAGEMENT_FEE_MAX
    self.token.transfer(self.rewards, fee)  # Thank you for your service!
    self.token.transfer(msg.sender, value - fee)


@view
@external
def pricePerShare() -> uint256:
    return self._shareValue(10 ** self.decimals)


@external
def addStrategy(
    _strategy: address,
    _startingCapital: uint256,
    _debtLimitCapital: uint256,
    _fadeIn: uint256,  # blocks
):
    assert msg.sender == self.governance
    starting: decimal = convert(_startingCapital, decimal)
    debtLimit: decimal = convert(_debtLimitCapital, decimal)
    self.strategies[_strategy] = StrategyParams({
        active: True,
        blockAdded: block.number,
        starting: starting,
        debtLimit: _debtLimitCapital,
        blockGain: (debtLimit - starting) / convert(_fadeIn, decimal),
        borrowed: _startingCapital,
        returns: 0,
    })
    self.borrowed += _startingCapital
    self.token.transfer(_strategy, _startingCapital)

    log StrategyUpdate(_strategy, 0, _startingCapital, 0, _startingCapital)


@external
def updateStrategy(_strategy: address, _debtLimit: uint256):
    assert msg.sender == self.governance
    self.strategies[_strategy].debtLimit = _debtLimit


@external
def migrateStrategy(_newVersion: address):
    """
    Only a strategy can migrate itself to a new version
    NOTE: Strategy must successfully migrate all capital and positions to
          new Strategy, or else this will upset the balance of the Vault
    """
    assert self.strategies[msg.sender].active
    assert not self.strategies[_newVersion].active
    strategy: StrategyParams = self.strategies[msg.sender]
    self.strategies[msg.sender] = empty(StrategyParams)
    self.strategies[_newVersion] = strategy
    # TODO: Ensure a smooth transition in terms of  strategy return


@external
def revokeStrategy(_strategy: address = msg.sender):
    """
    Governance can revoke a strategy
    OR
    A strategy can revoke itself (Emergency Exit Mode)
    """
    assert msg.sender in [_strategy, self.governance]
    self.strategies[_strategy].active = False


@view
@internal
def _available(_strategy: address) -> uint256:
    """
    Amount of tokens in vault a strategy has access to as a credit line
    """
    params: StrategyParams = self.strategies[_strategy]
    # Reserves available
    available: decimal = convert(self.token.balanceOf(self), decimal)
    # Adjust by % borrowed (vs. debt limit for strategy)
    available *= (convert(params.debtLimit, decimal) - convert(params.borrowed, decimal)) / convert(params.borrowed, decimal)
    # Adjust by initial rate limiting algorithm
    available *= min(
        params.starting + params.blockGain * convert((block.number - params.blockAdded), decimal),
        convert(params.debtLimit, decimal),
    )
    return convert(available, uint256)


@view
@external
def availableForStrategy(_strategy: address = msg.sender) -> uint256:
    if not self.strategies[_strategy].active or self.emergencyShutdown:
        return 0
    else:
        return self._available(_strategy)


@external
def sync(_repayment: uint256):
    """
    Strategies call this.
    _repayment: amount Strategy has freely available and is giving back to Vault
    """
    # NOTE: For approved strategies, this is the most efficient behavior.
    #       Strategy reports back what it has free (usually in terms of ROI)
    #       and then Vault "decides" here whether to take some back or give it more.
    #       Note that the most it can take is `_repayment`, and the most it can give is
    #       all of the remaining reserves. Anything outside of those bounds is abnormal
    #       behavior.
    # NOTE: This call is unprotected and that is acceptable behavior.
    #       In the scenario that msg.sender is not an approved strategy,
    #       then it will not be possible to get `creditline > 0` to trigger
    #       the first condition (which gets tokens). The call will revert if
    #       msg.sender is not an approved strategy and it is called with `_repayment > 0`.
    # NOTE: All approved strategies must have increased diligience around
    #       calling this function, as abnormal behavior could become catastrophic
    creditline: uint256 = 0  # If Emergency shutdown, than always take
    if self.strategies[msg.sender].active and not self.emergencyShutdown:
        # Only in normal operation do we extend a line of credit to the Strategy
        creditline = self._available(msg.sender)

    if _repayment < creditline:  # Underperforming, give a boost
        diff: uint256 = creditline - _repayment  # Give the difference
        self.token.transfer(msg.sender, diff)
        self.strategies[msg.sender].borrowed += diff
        self.borrowed += diff
    elif _repayment > creditline:  # Overperforming, take a cut
        diff: uint256 = _repayment - creditline  # Take the difference
        self.token.transferFrom(msg.sender, self, diff)
        # NOTE: Cannot return more than you borrowed (after adjusting for returns)
        self.strategies[msg.sender].borrowed -= diff
        self.borrowed -= diff
    # else if matching, don't do anything because it is performing well as is

    # Returns are always "realized gains"
    # NOTE: This is the only value an "attacker" can manipulate,
    #       but it doesn't have any sort of logical effect here.
    #       Basically, if you see a return w/ zero borrowed, it's not a strategy
    self.strategies[msg.sender].returns += _repayment

    log StrategyUpdate(
        msg.sender,
        _repayment,
        creditline,
        self.strategies[msg.sender].returns,
        self.strategies[msg.sender].borrowed,
    )
