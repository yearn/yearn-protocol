// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface CToken {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOfUnderlying(address) external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256) external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function approve(address, uint256) external returns (bool);
}
