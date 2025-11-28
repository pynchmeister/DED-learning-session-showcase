# 🎓 DED Learning Session — Public Showcase

A **public, educational showcase** of the core ideas behind **Decentralized Education Development (DED)**:

- On-chain **learning session artifacts** (videos, comments, etc.)
- Simple **threaded discussions** using parent/child relationships
- Lightweight **voting & reputation** for evaluating learning outcomes

> ⚠️ This repo is intentionally simplified and **omits production logic, economics, and advanced arbitration mechanisms**.  
> It is meant as a **conceptual & technical demo**, not the full DED protocol.

---

## 🌐 High-Level Idea

DED explores how to represent **learning sessions** and their outputs as **on-chain artifacts**:

- A **Student** completes a learning session and uploads an artifact (usually a video, or a reference to one).
- **Comments** can be attached to that artifact in a tree/thread structure.
- **Arbitrators / peers** can vote on artifacts to signal whether the learning goals were met.
- A simple **reputation score** is derived from votes across artifacts.

This repo shows a **minimal smart contract** expressing those ideas in Solidity, without revealing deeper protocol mechanics.

---

## 🧱 Core Solidity Contract

The core contract in this showcase:

- Stores **artifacts** (videos, comments) with:
  - `id`
  - `parentId`
  - `author`
  - `createdAtBlock`
  - `type` (VIDEO or COMMENT)
  - `CID` (content identifier for off-chain content, e.g. IPFS/Filecoin)
- Allows users to:
  - Create artifacts (`createArtifact`)
  - Read artifacts (`getArtifact`)
- Allows voters to:
  - Vote +1 / -1 / 0 on artifacts (`vote`)
  - Query aggregated scores for an artifact (`getArtifactScore`)
  - Query author reputation across their artifacts (`getAuthorReputation`)

All content payloads (video, text, etc.) are expected to be stored **off-chain** (e.g. IPFS, Filecoin, Web3.Storage) and referenced via the `CID` string.

---

## 🧩 Contract: `LearningSession.sol`

Key features:

- Simple **enum** for artifact type (`VIDEO`, `COMMENT`)
- `Artifact` struct with parent/child linking for threading
- Vote tracking per `(artifactId, voter)` using a `bytes32` voterId abstraction
- No token economics, no payouts, no access control beyond basic checks

📄 See [`src/LearningSession.sol`](./src/LearningSession.sol) for full details.

---

## ⚙️ Tech Stack

- **Solidity** `^0.8.20`
- **Foundry** (forge / cast)
- Minimal, framework-agnostic interface (no direct dependency on any frontend)

---

## 🚀 Getting Started (Foundry)

### 1. Install Foundry (if you haven’t yet)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

## 🔍 Design Notes

- This contract is intentionally minimal:
  - No roles, no economics, no complex arbitration
  - No assumptions about frontend, storage layer, or identity system
- The pattern is versatile and can be adapted to:
  - Peer review systems
  - Reputation-based knowledge networks
  - Educational DAOs
  - Content validation mechanisms

---

## ⚠️ Disclaimer

- This code is **not audited**
- It is for **educational & demonstration purposes only**
- Do **not** use as-is in production

---

## 🚀 Want to Explore or Extend?

Feel free to:

- Fork the repo  
- Add your own storage layer (IPFS, Filecoin, Web3.Storage, etc.)  
- Integrate with a frontend (React, Next.js, etc.)  
- Extend the reputation system with:
  - roles  
  - staking  
  - slashing  
  - more advanced arbitration logic (off-chain or on-chain)

If you build something cool on top, consider opening an issue or PR!

---

# 🛠️ Clone, Build, Test & Deploy

This section covers the full workflow for running the DED Learning Session showcase repo locally using **Foundry**.

---

## 📥 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/ded-learning-session-showcase.git
cd ded-learning-session-showcase
```

---

## 🧱 2. Install Dependencies

If using Foundry for the first time:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Install git submodules (if needed later):

```bash
git submodule update --init --recursive
```

---

## 🔨 3. Build the Contracts

Compile the project:

```bash
forge build
```

Expected output:

```
Compiling...
No errors or warnings
```

---

## 🧪 4. Run Tests (Optional)

Once tests are added in the `test/` directory, run:

```bash
forge test
```

This will:

- Execute unit tests  
- Show traces/logs  
- Display gas usage  

---

## 🚀 5. Deploy Locally With Anvil

Start a local Ethereum node:

```bash
anvil
```

Copy one of the private keys Anvil generates.

Deploy the contract:

```bash
RPC_URL=http://127.0.0.1:8545
PRIVATE_KEY=<paste-private-key>

forge script script/LearningSession.s.sol:LearningSessionScript \
  --fork-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

This will output:

- Contract address  
- Gas report  
- Transaction hash  

---

## 🌐 6. Deploy to a Remote Network (Optional)

Deploy to a testnet or EVM-compatible network:

```bash
RPC_URL=<https-or-ws-rpc-url>
PRIVATE_KEY=<your-private-key>

forge script script/LearningSession.s.sol:LearningSessionScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

> ⚠️ Never hardcode private keys.  
> Use environment variables or `.env` files.

---
