// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {MYieldToOne} from "../m0/MYieldToOne.sol";


import {ITeleportableExtension} from "./ITeleportableExtension.sol";

/// @title TeleportableTreasuryExtension
/// @notice Treasury-model M0 Extension where 100% yield goes to a treasury,
///         and which can be controlled by a Teleport bridge (mint/burn).
contract TeleportableTreasuryExtension is MYieldToOne, ITeleportableExtension {
    /// @notice Address of the Teleport bridge (TeleportPortal) allowed to mint/burn.
    address public bridge;

    event BridgeUpdated(address indexed newBridge);

    modifier onlyBridge() {
        require(msg.sender == bridge, "Teleport: not bridge");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address mToken_,
        address swapFacility_
    ) MYieldToOne(mToken_, swapFacility_) {
        _disableInitializers();
    }

    /// @notice Initialize the extension (same as normal Treasury model).
    /// @param name_   Token name (e.g. "My Teleportable Treasury USD")
    /// @param symbol_ Token symbol (e.g. "tUSD")
    /// @param yieldRecipient_ Treasury wallet that receives 100% yield
    /// @param admin_           DEFAULT_ADMIN_ROLE (usually a multisig)
    /// @param freezeManager_   FREEZE_MANAGER_ROLE
    /// @param yieldRecipientManager_ YIELD_RECIPIENT_MANAGER_ROLE
    function initialize(
        string memory name_,
        string memory symbol_,
        address yieldRecipient_,
        address admin_,
        address freezeManager_,
        address yieldRecipientManager_
    ) public initializer {
        MYieldToOne.initialize(
            name_,
            symbol_,
            yieldRecipient_,
            admin_,
            freezeManager_,
            yieldRecipientManager_
        );
    }

    /// @notice Set the bridge (TeleportPortal) allowed to mint/burn.
    /// @dev Restricted to DEFAULT_ADMIN_ROLE from MYieldToOne (AccessControl).
    function setBridge(
        address newBridge
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBridge != address(0), "Teleport: zero bridge");
        bridge = newBridge;
        emit BridgeUpdated(newBridge);
    }

    /// @inheritdoc ITeleportableExtension
    function mintFromBridge(
        address to,
        uint256 amount
    ) external override onlyBridge {
        // Uses internal _mint from MYieldToOne (which ultimately comes from MExtension).
        _mint(to, amount);
    }

    /// @inheritdoc ITeleportableExtension
    function burnFromBridge(
        address from,
        uint256 amount
    ) external override onlyBridge {
        // Uses internal _burn from MYieldToOne.
        _burn(from, amount);
    }
}
