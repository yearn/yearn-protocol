// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface yERC20 {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;
}
