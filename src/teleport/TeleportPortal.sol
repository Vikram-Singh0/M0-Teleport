// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {ITeleportableExtension} from "./ITeleportableExtension.sol";
import {ITeleportRouter} from "./ITeleportRouter.sol";
import {IERC20} from "../m0/IERC20.sol";

/// @title TeleportPortal
/// @notice Generic bridge portal for Teleportable M0 Extensions.
///         - On source chain: burns extension tokens and sends a message.
///         - On destination chain: receives message and mints tokens.
contract TeleportPortal {
    /// @notice The chain ID this portal considers "local".
    uint256 public immutable localChainId;

    /// @notice Owner for admin functions (token mappings, router).
    address public owner;

    /// @notice Cross-chain router (mock in local demo, can be Wormhole/Hyperlane later).
    ITeleportRouter public router;

    /// @notice Incrementing nonce for messages from this portal.
    uint256 public nextNonce;

    /// @notice Mapping of dstChainId => localToken => dstToken.
    ///         This tells the portal which token to mint on the destination chain.
    mapping(uint256 => mapping(address => address)) public remoteToken;

    /// @notice Used to prevent double-processing of the same message.
    mapping(bytes32 => bool) public processed;

    struct TeleportMessage {
        address token; // destination-chain token address
        address recipient; // recipient on destination chain
        uint256 amount;
        uint256 srcChainId;
        uint256 nonce;
    }

    event RouterUpdated(address indexed newRouter);
    event RemoteTokenSet(
        uint256 indexed dstChainId,
        address indexed localToken,
        address indexed remoteToken
    );
    event TeleportInitiated(
        uint256 indexed dstChainId,
        address indexed localToken,
        address indexed sender,
        address recipient,
        uint256 amount,
        uint256 nonce
    );
    event TeleportCompleted(
        address indexed token,
        address indexed recipient,
        uint256 amount,
        uint256 srcChainId,
        uint256 nonce
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "TeleportPortal: not owner");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == address(router), "TeleportPortal: not router");
        _;
    }

    constructor(address router_, uint256 localChainId_) {
        owner = msg.sender;
        router = ITeleportRouter(router_);
        localChainId = localChainId_;
    }

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(0), "TeleportPortal: zero router");
        router = ITeleportRouter(router_);
        emit RouterUpdated(router_);
    }

    /// @notice Map a local extension token to a destination-chain token.
    function setRemoteToken(
        uint256 dstChainId,
        address localToken,
        address dstToken
    ) external onlyOwner {
        require(
            localToken != address(0) && dstToken != address(0),
            "TeleportPortal: zero token"
        );
        remoteToken[dstChainId][localToken] = dstToken;
        emit RemoteTokenSet(dstChainId, localToken, dstToken);
    }

    /// @notice Initiate a teleport:
    ///         - transfer tokens from user to portal
    ///         - burn portal's balance via burnFromBridge
    ///         - send cross-chain message via router
    function teleport(
        address localToken,
        uint256 amount,
        uint256 dstChainId,
        address recipient
    ) external {
        require(amount > 0, "TeleportPortal: zero amount");
        require(recipient != address(0), "TeleportPortal: zero recipient");

        address dstToken = remoteToken[dstChainId][localToken];
        require(dstToken != address(0), "TeleportPortal: token not mapped");

        // 1) Pull tokens from user into the portal
        IERC20(localToken).transferFrom(msg.sender, address(this), amount);

        // 2) Burn from the portal's balance
        ITeleportableExtension(localToken).burnFromBridge(
            address(this),
            amount
        );

        // 3) Create cross-chain message
        uint256 nonce_ = nextNonce++;
        TeleportMessage memory m = TeleportMessage({
            token: dstToken,
            recipient: recipient,
            amount: amount,
            srcChainId: localChainId,
            nonce: nonce_
        });

        bytes memory payload = abi.encode(m);

        // 4) Send cross-chain message via router (mock in local setup)
        router.sendMessage(dstChainId, payload);

        emit TeleportInitiated(
            dstChainId,
            localToken,
            msg.sender,
            recipient,
            amount,
            nonce_
        );
    }

    /// @notice Called by router on the destination chain to mint tokens.
    function receiveMessage(bytes calldata payload) external onlyRouter {
        TeleportMessage memory m = abi.decode(payload, (TeleportMessage));

        bytes32 id = keccak256(
            abi.encode(m.token, m.recipient, m.amount, m.srcChainId, m.nonce)
        );
        require(!processed[id], "TeleportPortal: already processed");
        processed[id] = true;

        ITeleportableExtension(m.token).mintFromBridge(m.recipient, m.amount);

        emit TeleportCompleted(
            m.token,
            m.recipient,
            m.amount,
            m.srcChainId,
            m.nonce
        );
    }
}
