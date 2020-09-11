pragma solidity ^0.5.16;

interface AaveToken {
    function underlyingAssetAddress() external view returns (address);
}
