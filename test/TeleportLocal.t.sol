// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";

import "../src/mock/MockMToken.sol";
import "../src/mock/MockSwapFacility.sol";

import "../src/mock/MockRouter.sol";
import "../src/teleport/TeleportPortal.sol";
import "../src/teleport/TeleportableTreasuryExtension.sol";

contract TeleportLocalTest is Test {
    MockMToken mToken;
    MockSwapFacility swap;

    MockRouter router;

    TeleportPortal portalA;
    TeleportPortal portalB;

    TeleportableTreasuryExtension tokenA;
    TeleportableTreasuryExtension tokenB;

    address user = address(0x123);

    function setUp() public {
        /// Deploy mocks
        mToken = new MockMToken();
        swap = new MockSwapFacility();

        /// Mint M tokens to user
        mToken.mint(user, 1_000_000e6);

        /// Deploy router
        router = new MockRouter();

        /// Deploy portals — simulate Chain 1 and Chain 2
        portalA = new TeleportPortal(address(router), 1);
        portalB = new TeleportPortal(address(router), 2);

        /// Register portals in router
        router.registerPortal(1, address(portalA));
        router.registerPortal(2, address(portalB));

        /// Deploy Teleportable extension tokens
        tokenA = new TeleportableTreasuryExtension(
            address(mToken),
            address(swap)
        );
        tokenB = new TeleportableTreasuryExtension(
            address(mToken),
            address(swap)
        );

        /// Initialize tokens
        tokenA.initialize(
            "Teleport USD A",
            "tUSDA",
            address(this),
            address(this),
            address(this),
            address(this)
        );
        tokenB.initialize(
            "Teleport USD B",
            "tUSDB",
            address(this),
            address(this),
            address(this),
            address(this)
        );

        /// Set each token’s bridge
        tokenA.setBridge(address(portalA));
        tokenB.setBridge(address(portalB));

        /// Map tokens between chains
        portalA.setRemoteToken(2, address(tokenA), address(tokenB));
        portalB.setRemoteToken(1, address(tokenB), address(tokenA));
    }

    function test_teleport() public {
        uint256 amount = 100e6;

        /// User wraps M → tUSD (chain A)
        vm.startPrank(user);
        mToken.approve(address(tokenA), amount);
        tokenA.wrap(user, amount);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(user), amount);

        /// Approve portal to burn tokenA
        vm.startPrank(user);
        tokenA.approve(address(portalA), amount);

        /// Teleport token from chain A → chain B
        portalA.teleport(address(tokenA), amount, 2, user);
        vm.stopPrank();

        /// Check final balances
        assertEq(tokenA.balanceOf(user), 0, "tokenA should be burned");
        assertEq(tokenB.balanceOf(user), amount, "tokenB should be minted");
    }
}
