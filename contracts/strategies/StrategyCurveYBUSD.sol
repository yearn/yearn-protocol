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

contract StrategyCurveYBUSD {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want = address(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B);
    address constant public pool = address(0x69Fb7c45726cfE2baDeE8317005d3F94bE838840);
    address constant public mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address constant public uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // used for crv <> weth <> dai route

    address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address constant public ydai = address(0xC2cB1040220768554cf699b0d863A3cd4324ce32);
    address constant public curve = address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);

    uint public performanceFee = 500;
    uint constant public performanceMax = 10000;

    uint public withdrawalFee = 50;
    uint constant public withdrawalMax = 10000;

    address public governance;
    address public controller;
    address public strategist;

    constructor(address _controller) public {
        governance = msg.sender;
        strategist = msg.sender;
        controller = _controller;
    }

    function getName() external pure returns (string memory) {
        return "StrategyCurveYBUSD";
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
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
        require(crv != address(_asset), "crv");
        require(ydai != address(_asset), "ydai");
        require(dai != address(_asset), "dai");
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
        if (_crv > 0) {
            IERC20(crv).safeApprove(uni, 0);
            IERC20(crv).safeApprove(uni, _crv);

            address[] memory path = new address[](3);
            path[0] = crv;
            path[1] = weth;
            path[2] = dai;

            Uni(uni).swapExactTokensForTokens(_crv, uint(0), path, address(this), now.add(1800));
        }
        uint _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            IERC20(dai).safeApprove(ydai, 0);
            IERC20(dai).safeApprove(ydai, _dai);
            yERC20(ydai).deposit(_dai);
        }
        uint _ydai = IERC20(ydai).balanceOf(address(this));
        if (_ydai > 0) {
            IERC20(ydai).safeApprove(curve, 0);
            IERC20(ydai).safeApprove(curve, _ydai);
            ICurveFi(curve).add_liquidity([_ydai,0,0,0],0);
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
