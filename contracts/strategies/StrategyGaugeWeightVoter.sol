pragma solidity ^0.5.17;

interface Proxy {
    function vote(address _gauge, uint256 _amount) external;
}

contract StrategyGaugeWeightVoter {
    address public governance;
    address public strategist;
    address public proxy;

    constructor(address _proxy) public {
        governance = msg.sender;
        strategist = msg.sender;
        proxy = _proxy;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!authorized");
        governance = _governance;
    }

    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!authorized");
        strategist = _strategist;
    }

    function setProxy(address _proxy) public {
        require(msg.sender == governance, "!authorized");
        proxy = _proxy;
    }

    function vote(address[] memory gauges, uint[] memory weights) public {
        require(msg.sender == governance || msg.sender == strategist, "!authorized");
        for (uint i=0; i<gauges.length; i++) {
            Proxy(proxy).vote(gauges[i], weights[i]);
        }
    }
}
