Perfect — below is a **complete, A–Z README.md** you can directly copy-paste into your repo.
It is written as if **someone with zero context** is cloning your project and deploying it safely.

I’ve structured it exactly how reviewers, auditors, and hiring managers expect.

---

# 🏦 ERC-4626 Multi-Strategy Vault

A production-style **ERC-4626 compliant vault** that accepts USDC deposits, routes capital across multiple strategies, supports locked withdrawals via queues, and correctly prices shares based on aggregate value across underlying protocols.

This project mirrors real-world DeFi vault architectures used by yield aggregators and asset managers.

---

## 📌 Features Overview

* ERC-4626 compliant vault
* Multi-strategy capital allocation
* Dynamic share pricing via `totalAssets()`
* Withdrawal queue for locked strategies
* Manager-controlled rebalancing
* Allocation caps per strategy
* Role-based access control (OpenZeppelin)
* Invariant-based testing
* Local + testnet deployable

---

## 🗂️ Project Structure

```
VAULT-4626/
├── contracts/
│   ├── interfaces/        # Strategy & queue interfaces
│   ├── libraries/         # Math & allocation helpers
│   ├── mocks/
│   │   └── MockUSDC.sol   # Mock USDC token (6 decimals)
│   ├── strategies/
│   │   ├── StrategyA.sol  # Instant liquidity strategy
│   │   └── StrategyB.sol  # Locked liquidity strategy
│   └── vault.sol          # ERC-4626 Vault
│
├── scripts/
│   └── deploy.js          # Local/Testnet deployment script
│
├── test/
│   ├── helpers/           # Deploy & math helpers
│   └── invariants/        # Invariant-based tests
│
├── hardhat.config.js
├── package.json
├── .env.example
└── README.md
```

---

## 🔧 Prerequisites

Make sure you have the following installed:

* **Node.js** (v18+ recommended)
* **npm**
* **Hardhat**
* **MetaMask** (for testnet deployment)

---

## 📦 Installation

Clone the repository:

```bash
git clone https://github.com/your-username/vault-4626.git
cd vault-4626
```

Install dependencies:

```bash
npm install
```

---

## 🔐 Environment Setup

This project **does not include `.env` or `node_modules`** by default.

Create a `.env` file in the root directory:

```bash
touch .env
```

Add the following variables:

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
PRIVATE_KEY=YOUR_WALLET_PRIVATE_KEY
```

⚠️ **Important Notes**

* Use a **test wallet only**
* Never commit `.env`
* The private key must be a **32-byte hex key**, not an API key

---

## 🧪 Compile Contracts

```bash
npx hardhat compile
```

Expected output:

```text
Compiled XX Solidity files successfully
```

---

## ✅ Run Tests

This project uses **invariant testing** to validate safety guarantees.

```bash
npx hardhat test
```

Expected output:

```text
Vault – Invariant Tests
  ✔ Invariant: totalAssets >= strategy debt + idle
  ✔ Invariant: share price reflects totalAssets
  ✔ Invariant: withdraw burns shares
  ✔ Invariant: strategies cannot be drained by non-vault

4 passing
```

---

## 🧠 Deployment Scripts Explained

### `scripts/deploy.js`

Used for:

* Local deployment
* Testnet deployment
* Demo & Remix integration

Deploys in this order:

1. MockUSDC
2. Vault
3. StrategyA
4. StrategyB
5. Registers strategies
6. Executes initial rebalance

### `test/helpers/deploy.js`

Used **only for tests**

* Spins up clean deployments per test
* Should NOT be used for production deployment

✅ **Both scripts are required**

---

## 🚀 Local Deployment (Hardhat Node)

Start a local blockchain:

```bash
npx hardhat node
```

Deploy contracts:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

You’ll see deployed addresses printed in the terminal.

---

## 🌐 Testnet Deployment (Sepolia)

Ensure `.env` is configured correctly.

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

Contracts will deploy using your MetaMask wallet.

---

## 🧩 Remix Integration (Optional)

1. Open **Remix IDE**
2. Set environment to:

   * `Custom - External HTTP Provider`
   * URL: `http://127.0.0.1:8545`
3. Import contract files
4. **Do NOT use “At Address”**
5. Deploy fresh contracts for demo/testing

---

## 🔁 Testing Flow (Remix / Demo)

### Accounts

* **Account 0** → Manager
* **Account 1** → User

---

### Step 1: Mint & Distribute USDC

**Contract:** `MockUSDC`
**Caller:** Manager

```text
transfer(user, 1_000_000_000)
```

---

### Step 2: Approve Vault

**Contract:** `MockUSDC`
**Caller:** User

```text
approve(vault, 1_000_000_000)
```

---

### Step 3: Deposit into Vault

**Contract:** `Vault`
**Caller:** User

```text
deposit(1_000_000_000, user)
```

---

### Step 4: Add Strategies

**Contract:** `Vault`
**Caller:** Manager

```text
addStrategy(strategyA, 6000)
addStrategy(strategyB, 4000)
```

---

### Step 5: Rebalance

**Contract:** `Vault`
**Caller:** Manager

```text
rebalance()
```

---

### Step 6: Simulate Yield

**Contract:** `StrategyA`
**Caller:** Manager

```text
simulateYield(100_000_000)
```

---

### Step 7: Withdraw (Instant + Locked)

**Contract:** `Vault`
**Caller:** User

```text
withdraw(amount, user, user)
```

* Instant strategies pay immediately
* Locked strategies queue withdrawal

---

### Step 8: Claim Queued Withdrawals

**Contract:** `Vault`
**Caller:** User

```text
claim(requestId)
```

---

## 🔐 Roles & Access Control

* `MANAGER_ROLE`

  * addStrategy
  * rebalance
  * emergency controls

* Users:

  * deposit
  * withdraw
  * redeem
  * claim

---

## 🧠 Design Philosophy

* Vault aggregates value, strategies execute yield
* Interfaces decouple vault from protocol logic
* Withdrawal queue handles lockups safely
* Share pricing reflects real underlying value

---

## 🧪 Safety Guarantees

* Allocation caps prevent concentration risk
* Only vault can move strategy funds
* Invariant tests ensure solvency
* Access control enforced everywhere

---

## 👤 Author

Built by **Kunal Rosaili**
Web3 & Backend Engineer
Real-world smart contract development since 2023

---


