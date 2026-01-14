# Cellux Trade - Smart Contracts

![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![Foundry](https://img.shields.io/badge/Foundry-Latest-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

Perpetual futures trading protocol with **up to 100x leverage**, built on Mantle with Account Abstraction (USDC gas payments) and privileged smart wallets integration.

## 🌟 Key Features

- ⚡ **Instant Market Orders** - Execute trades immediately at current oracle price
- 📊 **High Leverage** - Up to 100x on BTC/ETH, 20x on altcoins
- 🎯 **Advanced Orders** - Limit orders, stop-loss, take-profit, grid trading
- 💵 **USDC Gas Payments** - Pay transaction fees in USDC via Account Abstraction
- 🎲 **One Tap Profit** - Short-term price prediction betting (30s-5min)
- 🔐 **Privy Smart Wallets** - Embedded wallets with email/social login
- 💎 **Dual Token Economy** - USDC for trading, CELL for governance & rewards

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Mantle Sepolia for deployment (get from [Mantle Sepolia Faucet](https://faucet.sepolia.mantle.xyz/))
- Private key with MNT for deployment

### Installation

```bash
# Clone repository
git clone <your-repo-url>
cd /cellux-sc

# Install dependencies
forge install

# Compile contracts
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run with verbose output
forge test -vvv
```

## 📁 Project Structure

```
cellux-sc/
├── src/
│   ├── token/
│   │   ├── CelluxToken.sol          # CELL governance token (10M supply)
│   │   └── MockUSDC.sol             # Test USDC with faucet
│   ├── risk/
│   │   └── RiskManager.sol          # Trade validation & risk checks
│   ├── trading/
│   │   ├── PositionManager.sol      # Position tracking & PnL calculation
│   │   ├── MarketExecutor.sol       # Market order execution
│   │   ├── LimitExecutor.sol      # Limit/stop-loss orders
│   │   ├── TapToTradeExecutor.sol   # Fast tap-to-trade orders
│   │   └── OneTapProfit.sol         # Price prediction betting
│   ├── treasury/
│   │   └── StabilityFund.sol      # Buffer first-loss, fee splitter, streaming
│   ├── paymaster/
│   │   └── USDCPaymaster.sol        # Account Abstraction paymaster
│   └── staking/
│       ├── CelluxStaking.sol        # Stake CELL → Earn USDC
│       └── VaultPool.sol      # LP vault (USDC shares)
├── script/
│   └── FullDeploy.s.sol             # Complete deployment script
├── test/                             # Foundry tests
└── foundry.toml                      # Foundry configuration
```

## 📦 Smart Contracts Overview

### Core Trading Contracts (5)

| Contract | Description | Key Features |
|----------|-------------|------------|
| **RiskManager** | Trade validation & risk management | Leverage limits (100x BTC/ETH, 20x alts), Liquidation checks |
| **PositionManager** | Position tracking & PnL | Real-time PnL calculation, Position history |
| **MarketExecutor** | Market order execution | Instant fills, Signed price verification |
| **LimitExecutor** | Advanced orders | Limit orders, Stop-loss, Take-profit, Grid trading |
| **StabilityFund** | Buffer first-loss, fee splitter, pays wins before pool | Absorbs losses, pays wins, streams surplus to pool |

### Infrastructure Contracts (3)

| Contract | Description | Purpose |
|----------|-------------|------|
| **CelluxToken** | CELL governance token | 10M supply, Staking rewards, Governance |
| **MockUSDC** | Test USDC | Faucet (1,000 USDC/claim) for testing |
| **USDCPaymaster** | Account Abstraction | Pay gas fees with USDC |

### Incentive Contracts (2)

| Contract | Description | Rewards |
|----------|-------------|------|
| **CelluxStaking** | Stake CELL tokens | Earn 30% of trading fees in USDC |
| **VaultPool** | Provide USDC liquidity | Share-based LP pool backing trader payouts |

### Specialty Trading (2)

| Contract | Description | Features |
|----------|-------------|------|
| **TapToTradeExecutor** | Fast order execution | Backend-managed instant trades |
| **OneTapProfit** | Price prediction betting | 30s-5min duration, 2x multiplier |

## 🔧 Deployment

### Quick Deploy (All Contracts)

```bash
forge script script/FullDeploy.s.sol \
  --rpc-url https://rpc.sepolia.mantle.xyz/ \
  --private-key YOUR_PRIVATE_KEY \
  --broadcast
```

This will:
1. Deploy core contracts (VaultPool, StabilityFund, Market/Limit/Tap/OTP, token, staking, paymaster)
2. Grant roles (SETTLER/KEEPER + backend signer)
3. Initialize CelluxToken distribution
4. Wire executors to StabilityFund and StabilityFund to VaultPool

### Deploy to Different Networks

**Mantle Sepolia (Testnet):**
```bash
forge script script/FullDeploy.s.sol \
  --rpc-url https://rpc.sepolia.mantle.xyz/ \
  --private-key YOUR_PRIVATE_KEY \
  --broadcast
```

**Mantle Mainnet (Production):**
```bash
forge script script/FullDeploy.s.sol \
  --rpc-url https://rpc.mantle.xyz/ \
  --private-key YOUR_PRIVATE_KEY \
  --broadcast \
  --verify
```

### Deployed Addresses (Mantle Sepolia)

```
MockUSDC: 0x9d660c5d4BFE4b7fcC76f327b22ABF7773DD48c1
CelluxToken: 0x53943f4f3d906A70dDc0ED5AEA0ed69bf9155F02
RiskManager: 0x8eA6059Bd95a9f0A47Ce361130ffB007415519aF
PositionManager: 0x69FFE0989234971eA2bc542c84c9861b0D8F9b17
VaultPool: 0x1183680b39fdfF834F47596cfBB8c6F504c39700
StabilityFund: 0xe2BF339Beb501f0C5263170189b6960AC416F1f3
MarketExecutor: 0x6D91332E27a5BddCe9486ad4e9cA3C319947a302
USDCPaymaster: 0x94FbB9C6C854599c7562c282eADa4889115CCd8E
LimitExecutor: 0x50951f3AE8e622E007A174e7AE08f25659bCe4B0
TapToTradeExecutor: 0xa1c84C31165282C05450b2a86f80999dD263b071
OneTapProfit: 0xCb5A11a2913763a01FA97CBDE67BCAB4Bf234D97
CelluxStaking: 0x94A0b7E05E07b507BF4e2870DD7B428a148C7eCb
```

## 💰 Token Distribution

**CELL Token (10,000,000 total):**
- 50% (5M) → Staking Rewards
- 20% (2M) -> VaultPool liquidity allocation  
- 20% (2M) → Team
- 10% (1M) → Treasury

Distribution is automatic during deployment via `CelluxToken.initialize()`.

## 💵 Fee Structure

| Action | Fee | Recipient |
|--------|-----|-----------|  
| Market Trade | 0.05% of position size | Protocol (split 50/30/20) |
| Limit Order Execution | 0.5 USDC | Keeper |
| Liquidation | 0.5% of position | Liquidator |
| Early Unstake (Staking) | 10% | Treasury |
| Early Withdrawal (LP) | 15% | Treasury |

**Fee Distribution:**
- 50% → Liquidity Pool (backs trader profits)
- 30% → CELL Stakers (via CelluxStaking)
- 20% → Protocol Treasury

## 🔐 Access Control & Roles

The deployment script automatically grants these roles:

### StabilityFund
- `EXECUTOR_ROLE` → MarketExecutor, LimitExecutor, TapToTradeExecutor, OneTapProfit
- `KEEPER_ROLE` → Backend keeper address (for liquidations)

### LimitExecutor
- `KEEPER_ROLE` → Backend keeper address (for limit order execution)

### MarketExecutor  
- `PRICE_SIGNER_ROLE` → Backend price signer address

## 🛡️ Security Features

- ✅ **OpenZeppelin Contracts** - Battle-tested security libraries
- ✅ **ReentrancyGuard** - All state-changing functions protected
- ✅ **Access Control** - Role-based permissions (RBAC)
- ✅ **SafeERC20** - Safe token transfers
- ✅ **Signed Prices** - ECDSA verification (5-minute validity)
- ✅ **Immutable Contracts** - No upgradability (trustless)
- ✅ **Oracle Validation** - Price freshness checks

## 📊 Leverage Limits

| Asset | Max Leverage | Min Collateral |
|-------|--------------|----------------|
| BTC | 100x | 10 USDC |
| ETH | 100x | 10 USDC |
| SOL, AVAX, NEAR | 50x | 10 USDC |
| BNB, XRP, LINK, MATIC | 20x | 10 USDC |
| AAVE, ARB, DOGE | 20x | 10 USDC |

## 🧪 Testing

```bash
# Run all tests
forge test

# Test specific contract
forge test --match-contract PositionManagerTest

# Test with gas report
forge test --gas-report

# Test with coverage
forge coverage
```

## 🚀 Next Steps

After deploying contracts:

1. **Update Backend**
   - Copy contract addresses to `cellux-be/.env`
   - Grant PRICE_SIGNER_ROLE to backend signer
   - Fund relay wallet with MNT

2. **Update Frontend**
   - Update contract addresses in frontend config
   - Test market orders
   - Test limit orders

3. **Add Liquidity**
   - Fund StabilityFund (buffer) and VaultPool with USDC (mint/transfer for testing)
   - Initial recommendation: 10,000 USDC minimum

4. **Test Trading**
   - Claim Mock USDC from faucet
   - Open test positions
   - Verify PnL calculations

## 🔗 Important Links

- [Mantle Sepolia Explorer](https://sepolia.mantlescan.xyz/)
- [Mantle Mainnet Explorer](https://mantlescan.xyz/)
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

## 📄 License

MIT License - see [LICENSE](./LICENSE) file for details

---

**Built with ❤️ by Cellux Trade Team using Foundry**

For questions or support, please open an issue on GitHub.
