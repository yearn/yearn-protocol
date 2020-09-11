// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface Uni {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}
