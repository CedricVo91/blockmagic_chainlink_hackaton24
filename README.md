# Decentralized Exchange (DEX) with AMM and Cross-Chain USDC Transfer

## Overview

This repository contains the implementation of a Decentralized Exchange (DEX) with an Automated Market Maker (AMM) model mimicking Uniswap's core contract design. Additionally, it includes a contract for sending USDC cross-chain to the DEX using Chainlink's CCIP.

## Main Files

- `factory_final_v3.sol`: The factory contract responsible for creating new pairs of tokens.
- `Pair_final_v3.sol`: The pair contract implementing the AMM logic for token swaps.
- `TransferUSDCBasic.sol`: The contract for sending USDC cross-chain to the DEX.

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

## Conclusion

This demonstration shows how the AMM dynamically adjusts token prices based on liquidity and trades. The DEX price is influenced by the internal state of the reserves, while the market price remains consistent with external price feeds.

The integration with Chainlink's CCIP in `TransferUSDCBasic.sol` enables cross-chain functionality, allowing for seamless token transfers between different blockchain networks.

Thank you for exploring this project!
