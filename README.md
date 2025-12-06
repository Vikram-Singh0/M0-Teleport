M0-Teleport 🚀
Universal Cross-Chain Teleporter for All M0 Extensions

M0-Teleport is a generalized cross-chain messaging and transfer layer built specifically for the M0 Extension Ecosystem.
It enables any M0-based stablecoin (Treasury, User-Yield, Institutional extensions) to be moved across any supported chain, regardless of which bridging protocol M0 natively exposes.

This makes M0-Teleport the missing interoperability layer that connects the entire M0 stablecoin universe.

🌍 Why M0-Teleport?

M0 provides powerful primitives:

$M – The fully collateralized, yield-bearing base money

Extensions – Custom stablecoins wrapping $M

SwapFacility – The canonical 1:1 conversion engine

Portals – Wormhole-NTT & Hyperlane based bridging

But each Portal only supports certain chain pairs:

Portal Type	Protocol	Supported Routes
M Portal	Wormhole NTT	Ethereum ↔ Arbitrum, Ethereum ↔ Optimism
M Portal Lite	Hyperlane	Ethereum ↔ Plume, Ethereum ↔ HyperEVM

As a result, M0 Extensions cannot freely move across all chains.

M0-Teleport solves this gap.

It provides a unified teleportation layer that sits above both Portal systems and adds routing logic so that:

Any M0 Extension → Any Chain → Same Extension on Destination Chain

No matter what bridging protocol the destination chain uses.

✨ What M0-Teleport Does
✔️ Supports all 3 M0 Extension Models
Extension Type	Supported?	Notes
Treasury Model (Yield-to-One)	✅	Yield ownership preserved across teleport
User-Yield Model	🚧 (planned)	Yield index preservation rules defined
Institutional Model	🚧 (planned)	Whitelist & compliance enforced pre-teleport
🧱 High-Level Architecture
+---------------------------------------------------------+
|                    User / Frontend UI                   |
+-------------------------------+-------------------------+
                                |
                                v
+---------------------------------------------------------+
|                    TeleportPortal.sol                   |
|  - Entry point for all outbound teleports               |
|  - Handles: fee quoting, routing, validation            |
|  - Normalizes requests for Wormhole/Hyperlane           |
+-------------------------------+-------------------------+
                                |
                                v
+---------------------------------------------------------+
|         Protocol Adapter Layer (Wormhole / Hyperlane)   |
|  - WHAdapter: talks to M Portal (Wormhole NTT)          |
|  - HLAdapter: talks to M Portal Lite (Hyperlane)        |
+-------------------------------+-------------------------+
                                |
                                v
+---------------------------------------------------------+
|                 Target Chain Teleport Receiver          |
|  - Deploys equivalent Extension contracts               |
|  - Receives messages                                    |
|  - Mints the corresponding M0 Extension tokens          |
+---------------------------------------------------------+
                                |
                                v
+---------------------------------------------------------+
|                        SwapFacility                     |
|          1:1 conversion between $M and Extensions       |
+---------------------------------------------------------+
                                |
                                v
+---------------------------+-----------------------------+
|             $M Token (Foundational Money Layer)         |
+---------------------------------------------------------+

⚙️ Workflow Overview
1. User initiates teleport
teleport(extension, amount, destinationChain, recipient)


The TeleportPortal figures out:

Which Portal to use (Wormhole vs Hyperlane)

Delivery fee quoting

Encoding calldata for the destination chain

Burn + lock flow for the outgoing chain

2. Contract burns the extension token
_wrap / _unwrap


This is inherited from MExtension:

Burn extension token on source chain

Release wrapped $M back to the SwapFacility

Prepare teleport message

3. Cross-chain message sent

Depending on chain pair:

Source → Destination	Protocol Used
Ethereum → Arbitrum	Wormhole NTT
Ethereum → Optimism	Wormhole NTT
Ethereum → Plume	Hyperlane
Ethereum → HyperEVM	Hyperlane
L2 → L2	Route through Ethereum hub
4. Destination chain receives message

The receiver contract:

Validates the message origin

Calls wrap on the destination Extension contract

Mints equivalent Extension tokens to the user

5. User receives the same stablecoin on a new chain

Teleport complete.
Value preserved 1:1.
Yield state preserved depending on extension type.

📦 Repository Structure
M0-Teleport/
│
├── src/
│   ├── teleport/
│   │   ├── TeleportPortal.sol        # Main orchestrator
│   │   ├── adapters/                 # Wormhole & Hyperlane logic
│   │   ├── TeleportableExtension.sol # Base class for teleport-enabled extensions
│   │
│   ├── m0/
│   │   ├── MExtension.sol
│   │   ├── MYieldToOne.sol
│   │   ├── interfaces/
│   │   └── swap/
│
├── test/
│   ├── Teleport.foundry.t.sol       # Local routing tests
│   ├── MockPortal.sol               # Mock Wormhole/Hyperlane
│   └── MockExtension.sol
│
├── script/
│   ├── DeployTeleport.s.sol
│   ├── DeployExtension.s.sol
│
└── README.md

🛠 How It Works (Core Logic)
TeleportPortal.sol

Packs and routes cross-chain messages

Selects Wormhole or Hyperlane by chainId mapping

Handles fee quoting

Verifies extension addresses & swap facility alignment

Ensures only the registered extension can request a teleport

TeleportableExtension.sol

Inherits from MExtension + your chosen model (MYieldToOne)

Adds:

function teleport(...) external returns (bytes32 sequence)


Burns tokens

Passes message to TeleportPortal

Receiver Logic

On destination chain:

_onMessageReceived(...)
→ call wrap()
→ mint teleported extension tokens

🚀 Local Testing Strategy

Includes:

Simulated Wormhole delivery

Simulated Hyperlane delivery

Round-trip test (A → B → A)

Yield index preservation

Supply integrity checks

🔮 Future Plans

Support for User-Yield extensions

Support for Institutional extensions with KYC gating

Automated bridging fee arbitrage routing

Intent-based “best route” solver (multi-hop M0 teleports)

Frontend dashboard showcasing:

All M0 extensions on all chains

Teleport history

Yield continuity



👨‍💻 Author

Vikram Singh
