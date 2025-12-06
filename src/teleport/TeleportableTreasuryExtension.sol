// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {MYieldToOne} from "../m0/MYieldToOne.sol";
import {IMExtension} from "../m0/IMExtension.sol";
import {TeleportPortal} from "./TeleportPortal.sol";

/**
 * @title TeleportableTreasuryExtension
 * @notice A Treasury Model M0 Extension that supports Teleport-style cross-chain mint/burn.
 */
contract TeleportableTreasuryExtension is MYieldToOne {
    /// @notice Address of TeleportPortal allowed to mint/burn this token
    address public bridge;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address mToken_,
        address swapFacility_
    ) MYieldToOne(mToken_, swapFacility_) {
        _disableInitializers();
    }

    /**
     * @notice Initialize Treasury Extension
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address yieldRecipient_,
        address admin,
        address freezeManager,
        address yieldRecipientManager
    ) public initializer {
        MYieldToOne.initialize(
            name_,
            symbol_,
            yieldRecipient_,
            admin,
            freezeManager,
            yieldRecipientManager
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                              Teleport Logic                                 */
    /* -------------------------------------------------------------------------- */

    modifier onlyBridge() {
        require(msg.sender == bridge, "Teleport: not bridge");
        _;
    }

    /**
     * @notice Sets the bridge (TeleportPortal) allowed to mint/burn this token.
     */
    function setBridge(address bridge_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bridge_ != address(0), "bridge=0");
        bridge = bridge_;
    }

    /**
     * @dev Internal mint override. Accessible only by TeleportPortal.
     */
    function mintForTeleport(address to, uint256 amount) external onlyBridge {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens for teleport (called by TeleportPortal)
     */
    function burnForTeleport(address from, uint256 amount) external onlyBridge {
        _burn(from, amount);
    }
}
