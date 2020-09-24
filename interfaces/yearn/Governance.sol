// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface Governance {
    function withdraw(uint) external;
    function getReward() external;
    function stake(uint) external;
    function balanceOf(address) external view returns (uint);
    function exit() external;
    function voteFor(uint) external;
    function voteAgainst(uint) external;
}
