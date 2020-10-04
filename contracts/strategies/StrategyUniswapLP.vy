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


# implements: StrategyAPI


vault: public(VaultAPI)
strategist: public(address)
keeper: public(address)
governance: public(address)
pendingGovernance: public(address)
want: public(ERC20)
reserve: public(uint256)
emergencyExit: public(bool)


@external
def __init__(_vault: address, _governance: address):
    self.vault = VaultAPI(_vault)
    self.want = ERC20(self.vault.token())
    self.want.approve(self.vault.address, MAX_UINT256)
    self.strategist = msg.sender
    self.keeper = msg.sender
    self.governance = _governance


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
    return 0


@internal
def prepareReturn():
    pass


@internal
def adjustPosition():
    pass


@internal
def exitPosition():
    pass


@view
@external
def tendTrigger(gasCost: uint256) -> bool:
    return True


@external
def tend():
    assert msg.sender in [self.keeper, self.strategist, self.governance]
    self.adjustPosition()


@view
@external
def harvestTrigger(gasCost: uint256) -> bool:
    return True


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
