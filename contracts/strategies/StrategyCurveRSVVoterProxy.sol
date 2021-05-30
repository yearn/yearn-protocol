// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.5.17;

import "@openzeppelinV2/contracts/token/ERC20/IERC20.sol";
import "@openzeppelinV2/contracts/math/SafeMath.sol";
import "@openzeppelinV2/contracts/utils/Address.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/yearn/IController.sol";
import "../../interfaces/curve/Curve.sol";

interface IVoterProxy {
    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(address _gauge) external view returns (uint256);

    function withdrawAll(address _gauge, address _token) external returns (uint256);

    function deposit(address _gauge, address _token) external;

    function harvest(address _gauge) external;

    function lock() external;

    function claimRewards(address _gauge, address _token) external;

    function approveStrategy(address _gauge, address _strategy) external;
}

contract StrategyCurveRSVVoterProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant want = address(0xC2Ee6b0334C261ED60C72f6054450b61B8f18E35);
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    address public constant curve = address(0xC18cC39da8b11dA8c3541C598eE022258F9744da);
    address public constant gauge = address(0x4dC4A289a8E33600D8bD4cf5F6313E43a37adec7);
    address public constant voter = address(0xF147b8125d2ef93FB6965Db97D6746952a133934);

    address public constant rsv = address(0x196f4727526eA7FB1e17b2071B3d8eAA38486988);
    address public constant rsr = address(0x8762db106B2c2A0bccB3A80d1Ed41273552616E8);

    address public constant oneinch = address(0x111111125434b319222CdBf8C261674aDB56F3ae);

    uint256 public keepCRV = 500;
    uint256 public treasuryFee = 1000;
    uint256 public strategistReward = 1000;
    uint256 public withdrawalFee = 0;
    uint256 public constant FEE_DENOMINATOR = 10000;

    address public proxy;
    address public dex;

    address public governance;
    address public controller;
    address public strategist;
    address public keeper;

    uint256 public earned; // lifetime strategy earnings denominated in `want` token

    event Harvested(uint256 wantEarned, uint256 lifetimeEarned);

    constructor(address _controller) public {
        governance = msg.sender;
        strategist = msg.sender;
        keeper = msg.sender;
        controller = _controller;
        // standardize constructor
        proxy = address(0x9a3a03C614dc467ACC3e81275468e033c98d960E);
    }

    function getName() external pure returns (string memory) {
        return "StrategyCurveRSVVoterProxy";
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        strategist = _strategist;
    }

    function setKeeper(address _keeper) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        keeper = _keeper;
    }

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setTreasuryFee(uint256 _treasuryFee) external {
        require(msg.sender == governance, "!governance");
        treasuryFee = _treasuryFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == governance, "!governance");
        strategistReward = _strategistReward;
    }

    function setProxy(address _proxy) external {
        require(msg.sender == governance, "!governance");
        proxy = _proxy;
    }

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeTransfer(proxy, _want);
            IVoterProxy(proxy).deposit(gauge, want);
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(crv != address(_asset), "crv");
        require(rsv != address(_asset), "rsv");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

        IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        return IVoterProxy(proxy).withdraw(gauge, want, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }

    function _withdrawAll() internal {
        IVoterProxy(proxy).withdrawAll(gauge, want);
    }

    function swapViaOneInch(
        address _token,
        uint256 _amount,
        bytes memory callData
    ) internal {
        IERC20(_token).approve(oneinch, _amount);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = address(oneinch).call(callData);
        if (!success) revert("1Inch-swap-failed");
    }

    function harvest(bytes memory crvCallData, bytes memory rsrCallData) public {
        require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance, "!keepers");

        // harvest CRV rewards
        IVoterProxy(proxy).harvest(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            uint256 _keepCRV = _crv.mul(keepCRV).div(FEE_DENOMINATOR);
            IERC20(crv).safeTransfer(voter, _keepCRV);
            _crv = _crv.sub(_keepCRV);
            swapViaOneInch(crv, _crv, crvCallData);
        }

        // harvest RSR rewards
        IVoterProxy(proxy).claimRewards(gauge, rsr);
        uint256 _rsr = IERC20(rsr).balanceOf(address(this));

        if (_rsr > 0) {
            swapViaOneInch(rsr, _rsr, rsrCallData);
        }

        // deposit all RSV to the Curve pool
        uint256 _rsv = IERC20(rsv).balanceOf(address(this));
        if (_rsv > 0) {
            IERC20(rsv).safeApprove(curve, 0);
            IERC20(rsv).safeApprove(curve, _rsv);
            ICurveFi(curve).add_liquidity([_rsv, 0], 0);
        }
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            uint256 _fee = _want.mul(treasuryFee).div(FEE_DENOMINATOR);
            uint256 _reward = _want.mul(strategistReward).div(FEE_DENOMINATOR);
            IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
            IERC20(want).safeTransfer(strategist, _reward);
            deposit();
        }
        IVoterProxy(proxy).lock();
        earned = earned.add(_want);
        emit Harvested(_want, earned);
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return IVoterProxy(proxy).balanceOf(gauge);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
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
