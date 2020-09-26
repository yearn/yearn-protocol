// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface VoteEscrow {
    function create_lock(uint, uint) external;
    function increase_amount(uint) external;
    function withdraw() external;
}
