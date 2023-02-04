// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Gradual Dutch Auction
/// @author transmissions11 <t11s@paradigm.xyz>
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @notice Sell token/tokens according to a price schedule.
abstract contract GDA {
    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable initialPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets target price and per time unit price decay for the VRGDA.
    /// @param _initialPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    constructor(int256 _initialPrice, int256 _priceDecayPercent) {
        initialPrice = _initialPrice;

        decayConstant = wadLn(1e18 - _priceDecayPercent);

        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the GDA began, scaled by 1e18.
    /// @return The price of a token according to GDA, scaled by 1e18.
    function getPrice(int256 timeSinceStart)
        public
        view
        virtual
        returns (uint256)
    {
        return
            uint256(
                wadMul(
                    initialPrice,
                    wadExp(unsafeWadMul(decayConstant, timeSinceStart))
                )
            );
    }
}
