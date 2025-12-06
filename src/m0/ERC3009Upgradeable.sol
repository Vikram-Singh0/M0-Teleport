// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

abstract contract ERC3009Upgradeable {
    /// @notice Tracks EIP-3009 nonces per user
    mapping(address => uint256) public nonces;

    /// @notice Domain separator for EIP-712 signatures
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice EIP-712 typehash for transferWithAuthorization
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x8a3a92f28b5c828a53ea50ccaa43d562e2eb06b1e0dab0633d5c0e54796a6d46;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    function __ERC3009_init(string memory name) internal {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @notice Verifies EIP-712 signature
    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        return ecrecover(digest, v, r, s) == signer;
    }

    /// @notice Marks an authorization as used
    function _useNonce(
        address authorizer
    ) internal returns (uint256 currentNonce) {
        currentNonce = nonces[authorizer]++;
        emit AuthorizationUsed(authorizer, bytes32(currentNonce));
    }

    function _getDigest(bytes32 structHash) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
            );
    }
}
