pragma solidity ^0.5.16;

interface Vault {
    function deposit(uint) external;
    function withdraw(uint) external;
    function getPricePerFullShare() external view returns (uint);
}
