// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {DA} from "src/DA.sol";

contract ExponentialDecayDA is DA {
    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets Initial price and per time unit price decay for the DA.
    /// @param _initialPrice The target price for a token, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time, scaled by 1e18.
    constructor(int256 _initialPrice, int256 _priceDecayPercent) DA(_initialPrice) {
        decayConstant = wadLn(1e18 - _priceDecayPercent);

        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /// @notice Calculate the price of a token according to a decaying price schedule.
    /// @param timeSinceStart Time passed since the DA began, scaled by 1e18.
    /// @return The price of a token according to DA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view virtual override returns (uint256) {
        return uint256(wadMul(initialPrice, wadExp(unsafeWadMul(decayConstant, timeSinceStart))));
    }
}
