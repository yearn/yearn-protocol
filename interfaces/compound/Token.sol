// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface cToken {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function underlying() external view returns (address);
}
