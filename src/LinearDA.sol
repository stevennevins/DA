// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {DA} from "src/DA.sol";

contract LinearDA is DA {
    int256 public immutable decayConstant;

    /// @notice Sets the initial price and per time unit price decay for the DA.
    /// @param _initialPrice The initial price of the token, scaled by 1e18.
    /// @param _decayConstant The percent price decays per unit of time, scaled by 1e18.
    constructor(int256 _initialPrice, int256 _decayConstant) DA(_initialPrice) {
        decayConstant = _decayConstant;

        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /// @notice Calculate the price of a token according to a decaying price schedule.
    /// @param timeSinceStart Time passed since the DA began, scaled by 1e18.
    /// @return The price of a token according to DA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view virtual override returns (uint256) {
        return uint256(initialPrice - unsafeWadMul(decayConstant, timeSinceStart));
    }
}
