/// SPDX-License-Identifier: SSPL-1.0
pragma solidity ^0.5.17;

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address);

    function getPriceOracle() external view returns (address);
}
