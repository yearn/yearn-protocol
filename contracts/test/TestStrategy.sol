// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import { BaseStrategy } from "../BaseStrategy.sol";

/*
 * This Strategy serves as both a mock Strategy for testing, and an example
 * for integrators on how to use BaseStrategy
 */

contract TestStrategy is BaseStrategy {
    constructor(address _vault, address _governance)
        BaseStrategy(_vault, _governance)
        public
    { }

    // When exiting the position, wait this many times to give everything back
    uint countdownTimer = 3;

    function tendTrigger(uint256 gasCost)
        public
        view
        override
        returns (bool)
    {
        // Dummy function
        return gasCost == 0;
    }

    function harvestTrigger(uint256 gasCost)
        public
        view
        override
        returns (bool)
    {
        // Dummy function
        return gasCost > 0;
    }

    function expectedReturn()
        public
        view
        override
        returns (uint256 er)
    {
        (,,,,, er) = vault.strategies(address(this));
    }

    function prepareReturn()
        internal
        override
    {
        // During testing, send this contract some tokens to simulate "Rewards"
    }

    function adjustPosition()
        internal
        override
    {
        // Whatever we have, consider it "invested" now
        reserve = want.balanceOf(address(this));
    }

    function exitPosition()
        internal
        override
    {
        // Dump 25% each time this is called, the first 3 times
        if (countdownTimer > 0) {
            reserve -= want.balanceOf(address(this)).div(4);
            countdownTimer -= 1;
        } else {
            reserve = 0;
        }
    }

    function prepareMigration(address _newStrategy)
        internal
        override
    {
        want.transfer(_newStrategy, want.balanceOf(address(this)));
    }
}
