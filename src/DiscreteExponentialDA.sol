// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {ExponentialDecayDA} from "src/ExponentialDA.sol";

contract ExponentialDiscreteDA is ExponentialDecayDA {
    int256 public immutable stepSize;

    /// @notice Sets Initial price and per time unit price decay for the DA.
    /// @param _initialPrice The target price for a token, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time, scaled by 1e18.
    constructor(
        int256 _initialPrice,
        int256 _priceDecayPercent,
        int256 _stepSize
    ) ExponentialDecayDA(_initialPrice, _priceDecayPercent) {
        stepSize = _stepSize;
    }

    /// @notice Calculate the price of a token according to a decaying price schedule.
    /// @param timeSinceStart Time passed since the DA began, scaled by 1e18.
    /// @return The price of a token according to DA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view override returns (uint256) {
        timeSinceStart = (timeSinceStart / stepSize) * stepSize;
        return uint256(wadMul(initialPrice, wadExp(unsafeWadMul(decayConstant, timeSinceStart))));
    }
}
