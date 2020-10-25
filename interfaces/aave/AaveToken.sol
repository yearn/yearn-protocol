/// SPDX-License-Identifier: SSPL-1.0
pragma solidity ^0.5.17;

interface AaveToken {
    function underlyingAssetAddress() external view returns (address);
}
