/// SPDX-License-Identifier: SSPL-1.0

pragma solidity ^0.5.17;

interface IConverter {
    function convert(address) external returns (uint256);
}
