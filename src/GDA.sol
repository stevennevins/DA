// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Gradual Dutch Auction
/// @notice Inspired by the VRGDAs.
/// @author steven <steven@tessera.co>
/// @notice Acknowledge transmissions11 <t11s@paradigm.xyz> for their VRGDA implementation
/// @notice Acknowledge FrankieIsLost <frankie@paradigm.xyz> for their VRGDA implementation
/// @notice Sell token/tokens according to a price schedule.
abstract contract GDA {
    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable initialPrice;

    /// @notice Sets target price and per time unit price decay for the VRGDA.
    /// @param _initialPrice The target price for a token if sold on pace, scaled by 1e18.
    constructor(int256 _initialPrice) {
        initialPrice = _initialPrice;
    }

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the GDA began, scaled by 1e18.
    /// @return The price of a token according to GDA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public virtual returns (uint256);
}

contract LinearGDA is GDA {
    int256 public immutable decayConstant;

    /// @notice Sets the initial price and per time unit price decay for the GDA.
    /// @param _initialPrice The initial price of the token, scaled by 1e18.
    /// @param _decayConstant The percent price decays per unit of time, scaled by 1e18.
    constructor(int256 _initialPrice, int256 _decayConstant) GDA(_initialPrice) {
        decayConstant = _decayConstant;

        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the GDA began, scaled by 1e18.
    /// @return The price of a token according to GDA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view virtual override returns (uint256) {
        return uint256(initialPrice - unsafeWadMul(decayConstant, timeSinceStart));
    }
}

contract LinearDiscreteGDA is LinearGDA {
    int256 public immutable stepSize;

    /// @notice Sets the initial price and per time unit price decay for the GDA.
    /// @param _initialPrice The initial price of the token, scaled by 1e18.
    /// @param _decayConstant The percent price decays per unit of time, scaled by 1e18.
    constructor(
        int256 _initialPrice,
        int256 _decayConstant,
        int256 _stepSize
    ) LinearGDA(_initialPrice, _decayConstant) {
        stepSize = _stepSize;
    }

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the GDA began, scaled by 1e18.
    /// @return The price of a token according to GDA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view override returns (uint256) {
        timeSinceStart = (timeSinceStart / stepSize) * stepSize;
        return (super.getPrice(timeSinceStart));
    }
}

contract ExponentialDecayGDA is GDA {
    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets Initial price and per time unit price decay for the GDA.
    /// @param _initialPrice The target price for a token, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time, scaled by 1e18.
    constructor(int256 _initialPrice, int256 _priceDecayPercent) GDA(_initialPrice) {
        decayConstant = wadLn(1e18 - _priceDecayPercent);

        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the GDA began, scaled by 1e18.
    /// @return The price of a token according to GDA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view virtual override returns (uint256) {
        return uint256(wadMul(initialPrice, wadExp(unsafeWadMul(decayConstant, timeSinceStart))));
    }
}

contract ExponentialDiscreteGDA is ExponentialDecayGDA {
    int256 public immutable stepSize;

    /// @notice Sets Initial price and per time unit price decay for the GDA.
    /// @param _initialPrice The target price for a token, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time, scaled by 1e18.
    constructor(
        int256 _initialPrice,
        int256 _priceDecayPercent,
        int256 _stepSize
    ) ExponentialDecayGDA(_initialPrice, _priceDecayPercent) {
        stepSize = _stepSize;
    }

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the GDA began, scaled by 1e18.
    /// @return The price of a token according to GDA, scaled by 1e18.
    function getPrice(int256 timeSinceStart) public view override returns (uint256) {
        timeSinceStart = (timeSinceStart / stepSize) * stepSize;
        return uint256(wadMul(initialPrice, wadExp(unsafeWadMul(decayConstant, timeSinceStart))));
    }
}
