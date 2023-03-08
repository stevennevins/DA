// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Dutch Auctions
/// @notice Inspired by the VRDAs.
/// @author steven <steven@tessera.co>
/// @notice Acknowledge transmissions11 <t11s@paradigm.xyz> for their VRDA implementation
/// @notice Acknowledge FrankieIsLost <frankie@paradigm.xyz> for their VRDA implementation
abstract contract DA {
    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable initialPrice;

    /// @notice Sets the initial price and per time unit price decay for the DA.
    /// @param _initialPrice The target price for a token if sold on pace, scaled by 1e18.
    constructor(int256 _initialPrice) {
        initialPrice = _initialPrice;
    }

    /// @notice Calculate the price of a token according to a decaying price schedule.
    /// @param timeSinceStart Time passed since the DA began, scaled by 1e18.
    /// @return The price of a token according to DA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public virtual returns (uint256);
}

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
