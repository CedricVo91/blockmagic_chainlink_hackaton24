# BlockMagic DEX - Chainlink Hackathon 2024

## Overview

A production-grade Decentralized Exchange (DEX) with Automated Market Maker (AMM) functionality and cross-chain capabilities using Chainlink CCIP. This project implements a Uniswap-style constant product AMM with enhanced security features, Chainlink price feeds integration, and cross-chain USDC transfers.

## 🚀 Features

- **AMM Implementation**: Constant product formula (x × y = k) similar to Uniswap
- **USD-Based Operations**: Add liquidity, remove liquidity, and swap using USD values
- **Chainlink Price Feeds**: Real-time price data with staleness validation
- **Cross-Chain USDC Transfers**: Powered by Chainlink CCIP
- **LP Token System**: ERC20 tokens representing liquidity provider shares
- **Security Features**: Reentrancy guards, access control, and comprehensive validation

## 📁 Project Structure

```
blockmagic_chainlink_hackaton24/
├── contracts/              # Main smart contracts (REFACTORED)
│   ├── Factory.sol        # Pair factory contract
│   ├── Pair_final_v3.sol  # AMM pair implementation
│   ├── LPToken.sol        # LP token with access control
│   ├── TransferUSDCBasic.sol  # CCIP USDC transfer
│   └── mocks/             # Mock contracts for testing
├── scripts/               # Python deployment scripts
│   └── config.py          # Network and deployment configuration
├── contracts_old/         # Legacy contracts (archived)
├── scripts_old/           # Old scripts (archived)
└── README.md             # This file
```

## 🔒 Security Improvements (Refactored)

This codebase has been comprehensively refactored with the following security enhancements:

### Critical Security Fixes
✅ **Access Control**: LP tokens use Ownable pattern - only Pair contracts can mint/burn
✅ **Reentrancy Protection**: All state-changing functions protected with ReentrancyGuard
✅ **Price Feed Validation**: Comprehensive staleness checks (1-hour timeout) and sanity validation
✅ **Checks-Effects-Interactions**: Proper CEI pattern implementation in swap and liquidity functions
✅ **Configurable Addresses**: Hard-coded addresses replaced with constructor parameters

### Code Quality Improvements
✅ **Constants Extracted**: Magic numbers replaced with named constants (`PRECISION`, `FEE_NUMERATOR`, etc.)
✅ **Events Added**: Comprehensive event logging (Swap, PairCreated, TokensReceived)
✅ **Documentation**: NatSpec comments for all public/external functions
✅ **Error Messages**: Descriptive require/revert messages throughout
✅ **Code Organization**: Logical grouping with clear section headers

## 📋 Main Contracts

### Factory.sol
Factory contract for creating trading pairs with automated LP token deployment.

**Key Functions**:
- `createPair()`: Deploys new Pair and LP token contracts, transfers ownership
- `getPair()`: Returns pair address for token combination
- `allPairsLength()`: Total number of deployed pairs

### Pair_final_v3.sol
Core AMM implementation with Chainlink integration.

**Key Functions**:
- `addLiquidityInUSD()`: Add liquidity using USD value
- `removeLiquidityInUSD()`: Remove liquidity using USD value
- `swapInUSD()`: Swap tokens using USD amount
- `getReserves()`: Get reserves and their USD values
- `getDEXPrice()`: Get AMM-based price
- `getMarketPrice()`: Get Chainlink oracle price

**Security Features**:
- Reentrancy guards on all state-changing functions
- Price feed validation with staleness checks
- Proper CEI pattern implementation

### LPToken.sol
ERC20 LP token with access control.

**Features**:
- Ownable pattern - only Pair contract can mint/burn
- Standard ERC20 functionality
- Automatic ownership transfer during deployment

### TransferUSDCBasic.sol
Cross-chain USDC transfers using Chainlink CCIP.

**Key Functions**:
- `transferUsdcToSepolia()`: Send USDC cross-chain
- `balancesOf()`: Check LINK and USDC balances
- `withdrawToken()`: Owner-only token withdrawal

## AMM Logic and Formula

The Automated Market Maker (AMM) model allows for decentralized trading without the need for an order book. It uses a constant product formula to ensure liquidity and price stability.

### Constant Product Formula

The AMM model follows the constant product formula:

\[ x \times y = k \]

Where:
- \( x \) is the reserve of token0 (USDC).
- \( y \) is the reserve of token1 (LINK).
- \( k \) is a constant, representing the product of the reserves.

This formula ensures that any trade must maintain the product of the reserves, which helps in determining the price of tokens.

### Price Calculation

The price of token1 (LINK) in terms of token0 (USDC) is given by:

\[ \text{Price of LINK} = \frac{\text{Reserve of USDC}}{\text{Reserve of LINK}} \]

This price dynamically adjusts based on the supply and demand of the tokens in the pool.

## Example Demonstration

Here, we walk through an example of adding liquidity, performing a swap, and removing liquidity to show how the AMM logic works.

### Initial Setup

- Token A: USDC (18 decimals)
- Token B: LINK (18 decimals)
- Initial liquidity added: 500 USDC and 27 LINK (total value ~1000 USD)

### Adding Liquidity

**Initial State:**

- `numberoftokens0 (USDC)`: 500
- `usdvalueoftokens0`: 499
- `numberoftokens1 (LINK)`: 27
- `usdvalueoftokens1`: 490

**DEX Price Calculation:**

\[ \text{DEX Price} = \frac{500 \times 10^{18}}{27} = 18.518518518518518518 \text{ USDC per LINK} \]

**Market Price Calculation:**

\[ \text{Market Price} = \frac{18.169869787401682129 \times 10^{18}}{1} = 18.169869787401682129 \text{ USDC per LINK} \]

### Swapping 500 USDC for LINK

**Before Swap:**

- Reserves:
  - `numberoftokens0 (USDC)`: 500
  - `numberoftokens1 (LINK)`: 27

**Amount of LINK received:**

\[ \text{Amount of LINK} = \frac{500 \times 27}{500 + 500} \times 0.997 = 13.4595 \]

**New Reserves:**

- `numberoftokens0 (USDC)`: 1000
- `numberoftokens1 (LINK)`: 13.5405
- `usdvalueoftokens0`: 999 (approximated)
- `usdvalueoftokens1`: 254 (approximated)

**New DEX Price:**

\[ \text{DEX Price} = \frac{1000 \times 10^{18}}{13.5405} = 71.428571428571428571 \text{ USDC per LINK} \]

**Market Price remains the same:**

\[ \text{Market Price} = 18.169869787401682129 \text{ USDC per LINK} \]

### Removing 500 USD of Liquidity

**Before Removal:**

- Reserves:
  - `numberoftokens0 (USDC)`: 1000
  - `numberoftokens1 (LINK)`: 13.5405

**Amounts after removing 500 USD of liquidity:**

**New Reserves:**

- `numberoftokens0 (USDC)`: 750
- `numberoftokens1 (LINK)`: 10.8405
- `usdvalueoftokens0`: 749 (approximated)
- `usdvalueoftokens1`: 199 (approximated)

**New DEX Price:**

\[ \text{DEX Price} = \frac{750 \times 10^{18}}{10.8405} = 68.181818181818181818 \text{ USDC per LINK} \]

**Market Price remains the same:**

\[ \text{Market Price} = 18.169869787401682129 \text{ USDC per LINK} \]

## 🛠️ Installation & Setup

### Prerequisites
- Node.js >= 16.0.0
- Python >= 3.8
- Ganache (for local testing)

### Installation Steps

1. **Install Node.js dependencies**:
```bash
npm install
```

2. **Install Python dependencies**:
```bash
pip install web3 py-solc-x python-dotenv
```

3. **Set up environment variables**:
```bash
export PRIVATE_KEY="your_private_key_here"
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/YOUR_INFURA_KEY"
```

⚠️ **Security Warning**: Never commit real private keys or API keys to the repository!

## ⚙️ Configuration

### Network Configuration

Edit `scripts/config.py` to configure:
- Network RPC URLs (Ganache, Sepolia, Arbitrum Sepolia)
- Contract addresses for different networks
- Chainlink price feed addresses
- Gas settings and compilation options

### Constants Reference

| Constant | Value | Description |
|----------|-------|-------------|
| `PRECISION` | 10^18 | Standard precision for calculations |
| `FEE_NUMERATOR` | 997 | Numerator for 0.3% swap fee |
| `FEE_DENOMINATOR` | 1000 | Denominator for fee calculation |
| `CHAINLINK_DECIMALS_ADJUSTMENT` | 10^10 | Converts Chainlink 8 decimals to 18 |
| `PRICE_FEED_TIMEOUT` | 3600 seconds | Maximum age for price feed data |

## 📚 Usage Examples

### Creating a Trading Pair

```solidity
Factory factory = Factory(factoryAddress);
address pair = factory.createPair(
    tokenA,           // Address of token A
    tokenB,           // Address of token B
    priceFeedA,       // Chainlink price feed for token A
    priceFeedB,       // Chainlink price feed for token B
    ccipRouter        // CCIP router address
);
```

### Adding Liquidity (USD-based)

```solidity
Pair pair = Pair(pairAddress);

// Approve tokens first
IERC20(tokenA).approve(pairAddress, amountA);
IERC20(tokenB).approve(pairAddress, amountB);

// Add $1000 worth of liquidity (split 50/50 between tokens)
pair.addLiquidityInUSD(1000 * 10**18);
```

### Swapping Tokens

```solidity
// Approve input token
IERC20(inputToken).approve(pairAddress, amount);

// Swap $100 worth of inputToken
pair.swapInUSD(100 * 10**18, inputToken);
```

### Cross-Chain USDC Transfer

```solidity
TransferUSDCBasic transfer = TransferUSDCBasic(transferAddress);

// Approve USDC
IERC20(usdc).approve(transferAddress, amount);

// Transfer 100 USDC to destination chain
bytes32 messageId = transfer.transferUsdcToSepolia(receiverAddress, 100 * 10**6);
```

## 🌐 Network Addresses

### Sepolia Testnet
- **CCIP Router**: `0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59`
- **LINK Token**: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- **USDC Token**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **Chain Selector**: `16015286601757825753`

### Arbitrum Sepolia
- **CCIP Router**: `0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165`
- **LINK Token**: `0xb1D4538B4571d411F07960EF2838Ce337FE1E80E`
- **USDC Token**: `0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d`
- **Chain Selector**: `3478487238524512106`

## 🔐 Security Considerations

⚠️ **Production Deployment Checklist**:

1. ✅ Price feed validation enabled (staleness checks)
2. ✅ Reentrancy protection on all functions
3. ✅ Access control for privileged operations
4. ✅ Input validation on all user inputs
5. ⚠️ Consider adding slippage protection for swaps
6. ⚠️ Conduct professional security audit before mainnet deployment

## 🚧 Known Limitations

1. **No Slippage Protection**: Users should implement slippage checks in their frontend
2. **Fixed Fee**: 0.3% fee is hard-coded (not configurable)
3. **USD-Only Public Functions**: Internal functions support direct token amounts
4. **Single Hop Swaps**: Multi-hop routing not implemented

## 🎯 Future Improvements

- [ ] Add slippage protection parameters to swap functions
- [ ] Implement multi-hop routing for better prices
- [ ] Add liquidity mining rewards system
- [ ] Create governance system for fee adjustment
- [ ] Add flash loan functionality
- [ ] Implement time-weighted average prices (TWAP)
- [ ] Add comprehensive test suite (Hardhat/Foundry)
- [ ] Add frontend interface

## 📄 License

MIT License - See LICENSE file for details

## 🏆 Hackathon Information

**Event**: Chainlink Hackathon 2024
**Project**: BlockMagic DEX
**Technologies**: Solidity, Chainlink CCIP, Chainlink Price Feeds, OpenZeppelin

## 📚 Resources

- [Chainlink Documentation](https://docs.chain.link/)
- [CCIP Documentation](https://docs.chain.link/ccip)
- [Chainlink Price Feeds](https://docs.chain.link/data-feeds)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf)

## 🙏 Acknowledgments

This project demonstrates the integration of Chainlink's industry-leading oracle infrastructure with DeFi primitives. The AMM logic demonstrates how Chainlink price feeds can be used alongside pool-based pricing for enhanced functionality.

---

**Note**: This codebase has been comprehensively refactored for improved security and code quality. Legacy code is preserved in `contracts_old/` and `scripts_old/` directories for reference.
