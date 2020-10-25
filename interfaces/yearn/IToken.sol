/// SPDX-License-Identifier: SSPL-1.0


pragma solidity ^0.5.17;

// NOTE: Basically an alias for Vaults
interface yERC20 {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function getPricePerFullShare() external view returns (uint256);
}
