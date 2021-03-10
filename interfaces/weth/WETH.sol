pragma solidity ^0.5.17;

interface WETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function totalSupply() external view returns (uint256);

    function approve(address to, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function balanceOf(address user) external returns (uint256);
}
