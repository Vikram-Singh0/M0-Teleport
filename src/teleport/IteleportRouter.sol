// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @notice Abstract router interface used by TeleportPortal to send cross-chain messages.
/// @dev In production, this could be Wormhole / Hyperlane / LayerZero. Here we'll mock it.
interface ITeleportRouter {
    function sendMessage(uint256 dstChainId, bytes calldata payload) external;
}
