// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface Proxy {
    function execute(address to, uint value, bytes calldata data) external returns (bool, bytes memory);
    function increaseAmount(uint) external;
}
