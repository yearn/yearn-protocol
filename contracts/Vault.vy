#@version 0.2.4

# TODO: Add ETH Configuration
# TODO: Add Delegated Configuration
from vyper.interfaces import ERC20

implements: ERC20

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

struct StrategyParams:
    blockAdded: uint256
    starting: uint256
    maximum: uint256
    blockGain: decimal
    borrowed: uint256
    returns: uint256

borrowed: public(uint256)  # Amount of tokens that all strategies have borrowed
strategies: public(HashMap[address, StrategyParams])


@external
def __init__(_token: address, _governance: address):
    self.token = ERC20(_token)
    self.name = concat("yearn", ERC20(_token).name())
    self.symbol = concat("yearn", ERC20(_token).symbol())
    self.decimals = ERC20(_token).decimals()
    self.governance = _governance
    self.guardian = msg.sender


@external
def setGovernance(_governance: address):
    assert msg.sender == self.governance
    self.governance = _governance


@external
def setGuardian(_guardian: address):
    assert msg.sender == self.guardian or msg.sender == self.governance
    self.guardian = _guardian


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
    log Transfer(ZERO_ADDRESS, _to, shares)


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
    self.balanceOf[_to] -= value
    log Transfer(_to, ZERO_ADDRESS, value)

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
    self.token.transfer(msg.sender, value)
@view
@external
def price() -> uint256:
    return self._shareValue(10 ** self.decimals)


@external
def addStrategy(
    _strategy: address,
    _startingCapital: uint256,
    _maximumCapital: uint256,
    _fadeIn: uint256,  # blocks
):
    assert msg.sender == self.governance
    self.strategies[_strategy] = StrategyParams({
        blockAdded: block.number,
        starting: _startingCapital,
        maximum: _maximumCapital,
        blockGain: convert(_maximumCapital - _startingCapital, decimal)) / convert(_fadeIn, decimal),
        borrowed: _startingCapital,
        returns: 0,
    })
    self.transfer(_strategy, _startingCapital)


@view
@internal
def _available(_strategy: address) -> uint256:
    """
    Amount of tokens in vault available to
    """
    params: StrategyParams = self.strategies[_strategy]
    # Reserves available
    available: decimal = convert(self.token.balanceOf(self), decimal)
    # Adjust by % borrowed
    available *= convert(params.maximum - params.borrowed, decimal) / convert(params.borrowed), decimal)
    # Adjust by initial rate limiting algorithm
    available *= min(
        params.starting + params.blockGain * convert((block.number - params.dateAdded), decimal),
        params.maximum,
    )
    return convert(available, uint256)


@view
@external
def available(_strategy: address) -> uint256:
    return self._available(_strategy)


@view
@external
def sync(_return: uint256) -> uint256:
    # NOTE: For approved strategies, this is the most efficient behavior.
    #       Strategy reports back what it has free (usually in terms of ROI)
    #       and then Vault "decides" here whether to take some back or give it more.
    #       Note that the most it can take is `_return`, and the most it can give is
    #       all of the remaining reserves. Anything outside of those bounds is abnormal
    #       behavior.
    # NOTE: This call is unprotected and that is acceptable behavior.
    #       In the scenario that msg.sender is not an approved strategy,
    #       then it will not be possible to get available > 0 to trigger
    #       the first condition (which gets tokens). The call will revert if
    #       msg.sender is not an approved strategy and it is called with _return > 0.
    # NOTE: All approved strategies must have increased diligience around
    #       calling this function, as abnormal behavior could become catastrophic
    available: uint256 = self._available(msg.sender)
    if _return < available:
        self.token.transfer(msg.sender, available - _return)
        self.strategies[msg.sender].borrowed += available - _return
        self.borrowed += available - _return
    elif _return > available:
        self.token.transferFrom(msg.sender, self, _return - available)
        self.strategies[msg.sender].borrowed += available
        self.borrowed += available
        if self.strategies[msg.sender].borrowed > _return:
            self.strategies[msg.sender].borrowed -= _return
        else:
            self.strategies[msg.sender].borrowed = 0
        if self.borrowed > _return:
            self.borrowed -= _return
        else:
            self.borrowed = 0
    # else if nothing to balance, don't do anything

    # Returns are always "realized gains"
    # NOTE: This is the only value an "attacker" can manipulate,
    #       but it doesn't have any sort of logical effect here.
    #       Basically, if you see a return w/ zero borrowed, it's not a strategy
    self.strategies[msg.sender].returns += _return

    return available
