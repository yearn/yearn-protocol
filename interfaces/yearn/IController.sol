pragma solidity ^0.5.16;

interface IController {
    function withdraw(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function earn(address, uint) external;
    function want(address) external view returns (address);
}
