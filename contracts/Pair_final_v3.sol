// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./LPToken.sol";

/**
 * @title Pair
 * @notice AMM trading pair with Chainlink CCIP integration for cross-chain operations
 * @dev Implements constant product formula (x * y = k) with Chainlink price feeds
 */
contract Pair is CCIPReceiver, ReentrancyGuard {
    // ============ Constants ============
    uint256 private constant PRECISION = 10**18;
    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private constant CHAINLINK_DECIMALS_ADJUSTMENT = 10**10; // 8 to 18 decimals
    uint256 private constant PRICE_FEED_TIMEOUT = 3600; // 1 hour staleness check

    // ============ State Variables ============
    address public token0;
    address public token1;
    LPToken public lpToken;

    uint256 public reserve0;
    uint256 public reserve1;

    AggregatorV3Interface internal priceFeed0;
    AggregatorV3Interface internal priceFeed1;

    // ============ Events ============
    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity, uint256 reserve0, uint256 reserve1);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity, uint256 reserve0, uint256 reserve1);
    event Swap(address indexed user, address indexed inputToken, address indexed outputToken, uint256 amountIn, uint256 amountOut);
    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);
    event TokensReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, address token, uint256 amount);

    bytes32 private s_lastReceivedMessageId;
    string private s_lastReceivedText;
    address private s_lastReceivedTokenAddress;
    uint256 private s_lastReceivedTokenAmount;

    constructor(
        address _token0,
        address _token1,
        address _priceFeed0,
        address _priceFeed1,
        address _lpToken,
        address _ccipRouter
    ) CCIPReceiver(_ccipRouter) {
        token0 = _token0;
        token1 = _token1;
        priceFeed0 = AggregatorV3Interface(_priceFeed0);
        priceFeed1 = AggregatorV3Interface(_priceFeed1);
        lpToken = LPToken(_lpToken);
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId;
        s_lastReceivedText = abi.decode(any2EvmMessage.data, (string));
        
        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            s_lastReceivedText
        );

        // Check if tokens are included in the message
        if (any2EvmMessage.destTokenAmounts.length > 0) {
            address receivedToken = any2EvmMessage.destTokenAmounts[0].token;
            uint256 receivedAmount = any2EvmMessage.destTokenAmounts[0].amount;

            emit TokensReceived(
                any2EvmMessage.messageId,
                any2EvmMessage.sourceChainSelector,
                abi.decode(any2EvmMessage.sender, (address)),
                receivedToken,
                receivedAmount
            );

            // Handle the received tokens
            _handleReceivedTokens(receivedToken, receivedAmount, abi.decode(any2EvmMessage.sender, (address)));
        }
    }

    function _handleReceivedTokens(address token, uint256 amount, address sender) internal {
        if (token == token0 || token == token1) {
            // If the token is part of the pair, perform a swap or other action
            // Example: Add liquidity or perform a swap
            // Add your logic here
        } else {
            // If the token is not part of the pair, return it to the sender with a message
            IERC20(token).transfer(sender, amount);
            // You can also send a cross-chain message back to the sender if needed
        }
    }

    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text, address tokenAddress, uint256 tokenAmount)
    {
        return (s_lastReceivedMessageId, s_lastReceivedText, s_lastReceivedTokenAddress, s_lastReceivedTokenAmount);
    }

    /**
     * @dev Internal function to add liquidity to the pool
     * @param amount0 Amount of token0 to add
     * @param amount1 Amount of token1 to add
     */
    function addLiquidity(uint256 amount0, uint256 amount1) internal nonReentrant {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        uint256 liquidity;
        if (lpToken.totalSupply() == 0) {
            liquidity = sqrt(amount0 * amount1);
        } else {
            liquidity = min(amount0 * lpToken.totalSupply() / reserve0, amount1 * lpToken.totalSupply() / reserve1);
        }

        require(liquidity > 0, "Insufficient liquidity provided");
        lpToken.mint(msg.sender, liquidity);

        reserve0 += amount0;
        reserve1 += amount1;
        emit LiquidityAdded(msg.sender, amount0, amount1, liquidity, reserve0, reserve1);
    }

    /**
     * @notice Add liquidity to the pool using USD-denominated amounts
     * @dev Splits USD amount equally between both tokens based on current prices
     * @param usdAmount Total USD value of liquidity to add (in 18 decimals)
     */
    function addLiquidityInUSD(uint256 usdAmount) external {
        // Fetch the current prices of token0 and token1 in USD
        uint256 price0 = uint256(getPrice(token0));
        uint256 price1 = uint256(getPrice(token1));

        // Calculate the amounts of token0 and token1 based on the USD value and their prices
        // Split the USD amount equally (50/50) between both tokens
        uint256 amount0 = (usdAmount * PRECISION) / (2 * price0);
        uint256 amount1 = (usdAmount * PRECISION) / (2 * price1);

        // Add liquidity to the pool without enforcing the ratio check
        addLiquidity(amount0, amount1);
    }

    /**
     * @dev Internal function to remove liquidity from the pool
     * @param liquidity Amount of LP tokens to burn
     */
    function removeLiquidity(uint256 liquidity) internal nonReentrant {
        require(liquidity > 0, "Insufficient liquidity");

        uint256 totalSupply = lpToken.totalSupply();
        uint256 amount0 = liquidity * reserve0 / totalSupply;
        uint256 amount1 = liquidity * reserve1 / totalSupply;

        require(amount0 > 0 && amount1 > 0, "Insufficient liquidity removed");

        // Effects
        lpToken.burn(msg.sender, liquidity);
        reserve0 -= amount0;
        reserve1 -= amount1;

        // Interactions
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);

        emit LiquidityRemoved(msg.sender, amount0, amount1, liquidity, reserve0, reserve1);
    }

    /**
     * @notice Remove liquidity from the pool using USD-denominated amounts
     * @dev Calculates LP tokens to burn based on USD value
     * @param usdAmount Total USD value of liquidity to remove (in 18 decimals)
     */
    function removeLiquidityInUSD(uint256 usdAmount) external {
        // Fetch the current prices of token0 and token1 in USD
        uint256 price0 = uint256(getPrice(token0));
        uint256 price1 = uint256(getPrice(token1));

        // Calculate the amounts of token0 and token1 based on the USD value and their prices
        uint256 amount0 = (usdAmount * PRECISION) / (2 * price0);
        uint256 amount1 = (usdAmount * PRECISION) / (2 * price1);

        // Calculate the liquidity to remove
        uint256 totalSupply = lpToken.totalSupply();
        uint256 liquidity = min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1);

        // Remove liquidity from the pool
        removeLiquidity(liquidity);
    }

    /**
     * @notice Get the current reserves and their USD values
     * @return numberoftokens0 Amount of token0 in reserves
     * @return usdvalueoftokens0 USD value of token0 reserves
     * @return numberoftokens1 Amount of token1 in reserves
     * @return usdvalueoftokens1 USD value of token1 reserves
     */
    function getReserves() public view returns (uint256 numberoftokens0, uint256 usdvalueoftokens0, uint256 numberoftokens1, uint256 usdvalueoftokens1) {
        uint256 reserve0InUSD = reserve0 * uint256(getPrice(token0)) / PRECISION;
        uint256 reserve1InUSD = reserve1 * uint256(getPrice(token1)) / PRECISION;
        return (reserve0, reserve0InUSD, reserve1, reserve1InUSD);
    }

    /**
     * @notice Get the current price of a token from Chainlink price feed
     * @dev Validates price feed data for staleness and sanity checks
     * @param inputToken Address of the token to get the price for
     * @return price Current price of the token in USD (18 decimals)
     */
    function getPrice(address inputToken) internal view returns (int price) {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");

        AggregatorV3Interface priceFeed = (inputToken == token0) ? priceFeed0 : priceFeed1;

        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();

        // Validate price feed data
        require(answer > 0, "Invalid price feed answer");
        require(updatedAt > 0, "Invalid price feed timestamp");
        require(answeredInRound >= roundId, "Stale price feed");
        require(block.timestamp - updatedAt <= PRICE_FEED_TIMEOUT, "Price feed timeout");

        // Adjust from 8 decimals (Chainlink) to 18 decimals
        return answer * int256(CHAINLINK_DECIMALS_ADJUSTMENT);
    }

    /**
     * @notice Get the price ratio between token0 and token1
     * @dev Uses validated price feeds with staleness checks
     * @return ratio Price ratio of token0 to token1 (18 decimals)
     */
    function getPriceRatio() internal view returns (int ratio) {
        int price0 = getPrice(token0);
        int price1 = getPrice(token1);
        return (price0 * int256(10**8)) / price1;
    }

    /**
     * @notice Calculate output amount for a given input using the constant product formula
     * @dev Applies 0.3% fee (997/1000) to input amount
     * @param amountIn Amount of the input token
     * @param inputToken Address of the input token
     * @return amountOut Amount of the output token
     */
    function getAmountOut(uint256 amountIn, address inputToken) internal view returns (uint256 amountOut) {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");
        require(amountIn > 0, "Insufficient input amount");

        bool isInputToken0 = (inputToken == token0);
        uint256 inputReserve = isInputToken0 ? reserve0 : reserve1;
        uint256 outputReserve = isInputToken0 ? reserve1 : reserve0;

        require(inputReserve > 0 && outputReserve > 0, "Insufficient liquidity");

        // Apply 0.3% fee: amountIn * 0.997
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR / FEE_DENOMINATOR;

        // Constant product formula: (x + Δx) * (y - Δy) = x * y
        amountOut = (amountInWithFee * outputReserve) / (inputReserve + amountInWithFee);
    }

    /**
     * @notice Swap tokens using USD-denominated amounts
     * @dev Follows checks-effects-interactions pattern to prevent reentrancy
     * @param usdAmount USD value to swap (in 18 decimals)
     * @param inputToken Address of the token to swap from
     */
    function swapInUSD(uint256 usdAmount, address inputToken) external nonReentrant {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");
        require(usdAmount > 0, "Invalid USD amount");

        // Fetch the current prices of token0 and token1 in USD
        uint256 price0 = uint256(getPrice(token0));
        uint256 price1 = uint256(getPrice(token1));

        bool isInputToken0 = (inputToken == token0);
        address outputToken = isInputToken0 ? token1 : token0;
        uint256 inputPrice = isInputToken0 ? price0 : price1;

        // Calculate the amount of input tokens based on the USD value
        uint256 amountIn = (usdAmount * PRECISION) / inputPrice;

        // Calculate the amount of output tokens using the AMM formula
        uint256 amountOut = getAmountOut(amountIn, inputToken);

        // Effects: Update reserves BEFORE interactions
        if (isInputToken0) {
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else {
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }

        // Interactions: Transfer tokens
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);
        IERC20(outputToken).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, inputToken, outputToken, amountIn, amountOut);
    }

    /**
     * @notice Get the DEX price of token1 in terms of token0 using the AMM formula
     * @dev Based on current pool reserves (x * y = k)
     * @return price Price of token1 in terms of token0 (18 decimals)
     */
    function getDEXPrice() public view returns (uint256 price) {
        require(reserve0 > 0 && reserve1 > 0, "Reserves are not set");
        return (reserve0 * PRECISION) / reserve1;
    }

    /**
     * @notice Get the market price of token1 in terms of token0 using Chainlink oracles
     * @dev Uses validated price feeds with staleness checks
     * @return price Market price of token1 in terms of token0 (18 decimals)
     */
    function getMarketPrice() public view returns (uint256 price) {
        int256 price0 = getPrice(token0); // Price of token0 in USD
        int256 price1 = getPrice(token1); // Price of token1 in USD
        return (uint256(price1) * PRECISION) / uint256(price0);
    }


    /**
     * @dev Helper function to compute square root (required for LP token minting).
     * @param y The number to compute the square root of.
     * @return z The square root of the number.
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @dev Helper function to find the minimum of two numbers.
     * @param x First number.
     * @param y Second number.
     * @return z Minimum of x and y.
     */
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    /**
     * @dev View function to get LP token details and balance for a specific address.
     * @param user Address of the user to check.
     * @return (address, uint256) Address of the LP token and balance of the user.
     */
    function getLPTokenDetails(address user) public view returns (address, uint256) {
        uint256 balance = lpToken.balanceOf(user);
        return (address(lpToken), balance);
    }
}
