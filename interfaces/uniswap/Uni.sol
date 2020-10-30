/// SPDX-License-Identifier: SSPL-1.0

pragma solidity ^0.5.17;

interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}
