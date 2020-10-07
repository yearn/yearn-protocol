// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface Vault {
    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function getPricePerFullShare() external view returns (uint256);
}
