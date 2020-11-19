# @version 0.2.7

interface OSM:
    def bud(user: address) -> (bool): view
    def peek() -> (uint256, bool): view
    def peep() -> (uint256, bool): view


owner: public(address)
users: public(HashMap[address, bool])
oracle: public(OSM)


@external
def __init__(src: address):
    self.owner = msg.sender
    self.oracle = OSM(src)


@external
def set_owner(new_owner: address):
    assert msg.sender == self.owner
    self.owner = new_owner


@external
def set_user(user: address, allowed: bool):
    assert msg.sender == self.owner
    self.users[user] = allowed


@view
@external
def peek() -> (uint256, bool):
    assert self.users[msg.sender], "not user"
    assert self.oracle.bud(self), "not bud"
    return self.oracle.peek()


@view
@external
def peep() -> (uint256, bool):
    assert self.users[msg.sender], "not user"
    assert self.oracle.bud(self), "not bud"
    return self.oracle.peep()
