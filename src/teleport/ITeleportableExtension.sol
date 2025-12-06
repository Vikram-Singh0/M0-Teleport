// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @notice Minimal interface that any M0 Extension token must implement
///         to be controlled by the Teleport bridge.
interface ITeleportableExtension {
    /// @notice Mint tokens on the destination chain, called only by the bridge.
    function mintFromBridge(address to, uint256 amount) external;

    /// @notice Burn tokens on the source chain, called only by the bridge.
    function burnFromBridge(address from, uint256 amount) external;
}
