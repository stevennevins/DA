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
