// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ITeleportRouter} from "../teleport/ITeleportRouter.sol";
import {TeleportPortal} from "../teleport/TeleportPortal.sol";

/// @title MockRouter
/// @notice Simple in-process router for local testing.
///         - For a given dstChainId, it knows which TeleportPortal to call.
///         - In real life, this would be Wormhole / Hyperlane.
contract MockRouter is ITeleportRouter {
    address public owner;

    /// @notice Mapping chainId => TeleportPortal address on that "chain".
    mapping(uint256 => address) public portalOfChain;

    event PortalRegistered(uint256 indexed chainId, address indexed portal);

    modifier onlyOwner() {
        require(msg.sender == owner, "MockRouter: not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Register a portal for a given chainId.
    /// @dev In local tests, you can treat different portals as different "chains".
    function registerPortal(
        uint256 chainId,
        address portal
    ) external onlyOwner {
        require(portal != address(0), "MockRouter: zero portal");
        portalOfChain[chainId] = portal;
        emit PortalRegistered(chainId, portal);
    }

    /// @inheritdoc ITeleportRouter
    function sendMessage(
        uint256 dstChainId,
        bytes calldata payload
    ) external override {
        address portal = portalOfChain[dstChainId];
        require(portal != address(0), "MockRouter: no portal for chain");

        // In a real bridge, this would be delivered by relayers on the destination chain.
        TeleportPortal(payable(portal)).receiveMessage(payload);
    }
}
