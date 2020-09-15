pragma solidity ^0.5.16;

interface DelegatedVault {
    function token() external view returns (address);
    function deposit(uint) external;
    function depositAll() external;
    function withdraw(uint) external;
    function withdrawAll() external;
    function getPricePerFullShare() external view returns (uint);
    function claimInsurance() external;
}
