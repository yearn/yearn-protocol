pragma solidity ^0.5.17;

interface FeeDistribution {
    function claim(address) external returns (uint256);
}
