pragma solidity =0.5.17;

import "@openzeppelinV2/contracts/token/ERC20/IERC20.sol";
import "@openzeppelinV2/contracts/math/SafeMath.sol";
import "@openzeppelinV2/contracts/utils/Address.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/yearn/OneSplitAudit.sol";

interface Governance {
    function notifyRewardAmount(uint) external;
}

interface ICurveExchange {
    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata min_amounts) external;
}

contract TreasuryVault {
    using SafeERC20 for IERC20;

    struct CurvePool {
        address swap;
        uint coins;
    }

    address public governance;
    address public onesplit;
    address public rewards = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address public ygov = address(0xBa37B002AbaFDd8E89a1995dA52740bbC013D992);

    mapping(address => bool) authorized;
    mapping(address => CurvePool) curvePools;

    constructor() public {
        governance = msg.sender;
        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    }

    function setOnesplit(address _onesplit) external {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }

    function setRewards(address _rewards) external {
        require(msg.sender == governance, "!governance");
        rewards = _rewards;
    }

    function setYGov(address _ygov) external {
        require(msg.sender == governance, "!governance");
        ygov = _ygov;
    }

    function setAuthorized(address _authorized) external {
        require(msg.sender == governance, "!governance");
        authorized[_authorized] = true;
    }

    function revokeAuthorized(address _authorized) external {
        require(msg.sender == governance, "!governance");
        authorized[_authorized] = false;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function toGovernance(address _token, uint _amount) external {
        require(msg.sender == governance, "!governance");
        IERC20(_token).safeTransfer(governance, _amount);
    }

    function toVoters() external {
        uint _balance = IERC20(rewards).balanceOf(address(this));
        IERC20(rewards).safeApprove(ygov, 0);
        IERC20(rewards).safeApprove(ygov, _balance);
        Governance(ygov).notifyRewardAmount(_balance);
    }

    function getExpectedReturn(
        address _from,
        address _to,
        uint parts
    ) external view returns (uint expected) {
        uint _balance = IERC20(_from).balanceOf(address(this));
        (expected, ) = OneSplitAudit(onesplit).getExpectedReturn(_from, _to, _balance, parts, 0);
    }

    function setCurvePools(
        address[] calldata tokens,
        address[] calldata pools,
        uint[] calldata coins
    ) external {
        require(msg.sender == governance, "!governance");
        for (uint i = 0; i < tokens.length; i++) {
            curvePools[tokens[i]] = CurvePool(pools[i], coins[i]);
        }
    }

    function withdrawCurve(address[] calldata tokens) external {
        require(authorized[msg.sender], "!authorized");
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == rewards) continue;
            CurvePool memory pool = curvePools[tokens[i]];
            if (pool.swap == address(0)) continue;
            uint balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance == 0) continue;
            if (pool.coins == 2) ICurveExchange(pool.swap).remove_liquidity(balance, [uint256(0), 0]);
            if (pool.coins == 3) ICurveExchange(pool.swap).remove_liquidity(balance, [uint256(0), 0, 0]);
            if (pool.coins == 4) ICurveExchange(pool.swap).remove_liquidity(balance, [uint256(0), 0, 0, 0]);
        }
    }

    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function convert(address _from, uint parts) external {
        require(authorized[msg.sender] == true, "!authorized");
        uint _amount = IERC20(_from).balanceOf(address(this));
        uint[] memory _distribution;
        uint _expected;
        IERC20(_from).safeApprove(onesplit, 0);
        IERC20(_from).safeApprove(onesplit, _amount);
        (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(_from, rewards, _amount, parts, 0);
        OneSplitAudit(onesplit).swap(_from, rewards, _amount, _expected, _distribution, 0);
    }
}
