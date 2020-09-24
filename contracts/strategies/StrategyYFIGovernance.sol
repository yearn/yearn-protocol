// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;


import "@openzeppelinV2/contracts/token/ERC20/IERC20.sol";
import "@openzeppelinV2/contracts/math/SafeMath.sol";
import "@openzeppelinV2/contracts/utils/Address.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/yearn/IController.sol";
import "../../interfaces/yearn/Governance.sol";
import "../../interfaces/yearn/Token.sol";
import "../../interfaces/uniswap/Uni.sol";
import "../../interfaces/curve/Curve.sol";

/*

 A strategy must implement the following calls;
 
 - deposit()
 - withdraw(address) must exclude any tokens used in the yield - Controller role - withdraw should return to Controller
 - withdraw(uint) - Controller | Vault role - withdraw should always return to vault
 - withdrawAll() - Controller | Vault role - withdraw should always return to vault
 - balanceOf()
 
 Where possible, strategies must remain as immutable as possible, instead of updating variables, we update the contract by linking it in the controller
 
*/

contract StrategyYFIGovernance {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public want = address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);
    address constant public gov = address(0xBa37B002AbaFDd8E89a1995dA52740bbC013D992);
    address constant public curve = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    address constant public zap = address(0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3);
    
    address constant public reward = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    
    address constant public uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // used for crv <> weth <> dai route
    
    uint public fee = 500;
    uint constant public max = 10000;
    
    address public governance;
    address public controller;
    address public strategist;
    
    constructor(address _controller) public {
        governance = msg.sender;
        strategist = msg.sender;
        controller = _controller;
    }
    
    function setFee(uint _fee) external {
        require(msg.sender == governance, "!governance");
        fee = _fee;
    }
    
    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }
    
    function deposit() public {
        IERC20(want).safeApprove(gov, 0);
        IERC20(want).safeApprove(gov, IERC20(want).balanceOf(address(this)));
        Governance(gov).stake(IERC20(want).balanceOf(address(this)));
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        
        uint _fee = _amount.mul(fee).div(max);
        IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        
        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        balance = IERC20(want).balanceOf(address(this));
        
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }
    
    function _withdrawAll() internal {
        Governance(gov).exit();
    }
    
    function harvest() public {
        require(msg.sender == strategist || msg.sender == governance || msg.sender == tx.origin, "!authorized");
        Governance(gov).getReward();
        uint _balance = IERC20(reward).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(reward).safeApprove(zap, 0);
            IERC20(reward).safeApprove(zap, _balance);
            Zap(zap).remove_liquidity_one_coin(_balance, 2, 0);
        }
        _balance = IERC20(usdt).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(usdt).safeApprove(uni, 0);
            IERC20(usdt).safeApprove(uni, _balance);
            
            address[] memory path = new address[](3);
            path[0] = usdt;
            path[1] = weth;
            path[2] = want;
            
            Uni(uni).swapExactTokensForTokens(_balance, uint(0), path, address(this), now.add(1800));
        }
        if (IERC20(want).balanceOf(address(this)) > 0) {
            deposit();
        }
        
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        Governance(gov).withdraw(_amount);
        return _amount;
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOfYGov() public view returns (uint) {
        return Governance(gov).balanceOf(address(this));
    }
    
    function balanceOf() public view returns (uint) {
        return balanceOfWant()
               .add(balanceOfYGov());
    }
    
    function voteFor(uint _proposal) external {
        require(msg.sender == governance, "!governance");
        Governance(gov).voteFor(_proposal);
    }
    
    function voteAgainst(uint _proposal) external {
        require(msg.sender == governance, "!governance");
        Governance(gov).voteAgainst(_proposal);
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}
