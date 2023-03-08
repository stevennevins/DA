// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {LinearDA} from "src/LinearDA.sol";

contract LinearDiscreteDA is LinearDA {
    int256 public immutable stepSize;

    /// @notice Sets the initial price and per time unit price decay for the DA.
    /// @param _initialPrice The initial price of the token, scaled by 1e18.
    /// @param _decayConstant The percent price decays per unit of time, scaled by 1e18.
    constructor(
        int256 _initialPrice,
        int256 _decayConstant,
        int256 _stepSize
    ) LinearDA(_initialPrice, _decayConstant) {
        stepSize = _stepSize;
    }

    /// @notice Calculate the price of a token according to a decaying price schedule.
    /// @param timeSinceStart Time passed since the DA began, scaled by 1e18.
    /// @return The price of a token according to DA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view override returns (uint256) {
        timeSinceStart = (timeSinceStart / stepSize) * stepSize;
        return (super.getPrice(timeSinceStart));
    }
}
