// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
}
