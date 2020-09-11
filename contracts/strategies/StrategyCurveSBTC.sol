// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

import "@openzeppelinV2/contracts/token/ERC20/IERC20.sol";
import "@openzeppelinV2/contracts/math/SafeMath.sol";
import "@openzeppelinV2/contracts/utils/Address.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/curve/Curve.sol";
import "../../interfaces/curve/Gauge.sol";
import "../../interfaces/uniswap/Uni.sol";

import "../../interfaces/yearn/IController.sol";
import "../../interfaces/yearn/Mintr.sol";
import "../../interfaces/yearn/Token.sol";

contract StrategyCurveSBTC {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address constant public want = address(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3);
    address constant public pool = address(0x705350c4BcD35c9441419DdD5d2f097d7a55410F);
    address constant public mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address constant public uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // used for crv <> weth <> wbtc route
    
    address constant public wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address constant public curve = address(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);
    
    uint public performanceFee = 500;
    uint constant public performanceMax = 10000;
    
    uint public withdrawalFee = 50;
    uint constant public withdrawalMax = 10000;
    
    uint public keepCRV = 1000;
    uint constant public keepCRVMax = 10000;
    
    address public governance;
    address public controller;
    address public strategist;
    
    constructor(address _controller) public {
        governance = msg.sender;
        strategist = msg.sender;
        controller = _controller;
    }
    
    function getName() external pure returns (string memory) {
        return "StrategyCurveSBTC";
    }
    
    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }
    
    function setKeepCRV(uint _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }
    
    function setWithdrawalFee(uint _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }
    
    function setPerformanceFee(uint _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }
    
    function deposit() public {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(pool, 0);
            IERC20(want).safeApprove(pool, _want);
            Gauge(pool).deposit(_want);
        }
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(wbtc != address(_asset), "wbtc");
        require(crv != address(_asset), "crv");
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
        
        uint _fee = _amount.mul(withdrawalFee).div(withdrawalMax);
        
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
        Gauge(pool).withdraw(Gauge(pool).balanceOf(address(this)));
    }
    
    function harvest() public {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        Mintr(mintr).mint(pool);
        uint _crv = IERC20(crv).balanceOf(address(this));
        
        uint _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
        IERC20(crv).safeTransfer(IController(controller).rewards(), _keepCRV);
        _crv = _crv.sub(_keepCRV);
        
        if (_crv > 0) {
            IERC20(crv).safeApprove(uni, 0);
            IERC20(crv).safeApprove(uni, _crv);
            
            address[] memory path = new address[](3);
            path[0] = crv;
            path[1] = weth;
            path[2] = wbtc;
            
            Uni(uni).swapExactTokensForTokens(_crv, uint(0), path, address(this), now.add(1800));
        }
        uint _wbtc = IERC20(wbtc).balanceOf(address(this));
        if (_wbtc > 0) {
            IERC20(wbtc).safeApprove(curve, 0);
            IERC20(wbtc).safeApprove(curve, _wbtc);
            ICurveFi(curve).add_liquidity([0,_wbtc,0],0);
        }
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            uint _fee = _want.mul(performanceFee).div(performanceMax);
            IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
            deposit();
        }
    }
    
    function _withdrawSome(uint256 _amount) internal returns (uint) {
        Gauge(pool).withdraw(_amount);
        return _amount;
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }
    
    function balanceOfPool() public view returns (uint) {
        return Gauge(pool).balanceOf(address(this));
    }
    
    function balanceOf() public view returns (uint) {
        return balanceOfWant()
               .add(balanceOfPool());
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
