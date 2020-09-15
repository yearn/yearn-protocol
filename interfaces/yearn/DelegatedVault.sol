pragma solidity ^0.5.16;

import "./Vault.sol";

interface DelegatedVault is Vault {
    function claimInsurance() external;
}
