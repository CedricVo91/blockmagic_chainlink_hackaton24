// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pair {
    // Token addresses for the pair
    address public token0;
    address public token1;

    // Reserves of each token in the pair
    uint256 public reserve0;
    uint256 public reserve1;

    // Chainlink price feeds for the tokens
    AggregatorV3Interface internal priceFeed0;
    AggregatorV3Interface internal priceFeed1;

    /**
     * @dev Constructor to initialize the pair contract with token addresses and price feeds.
     * @param _token0 Address of token0.
     * @param _token1 Address of token1.
     * @param _priceFeed0 Address of the Chainlink price feed for token0/USD.
     * @param _priceFeed1 Address of the Chainlink price feed for token1/USD.
     */
    constructor(
        address _token0,
        address _token1,
        address _priceFeed0, // Price feed for token0/USD
        address _priceFeed1  // Price feed for token1/USD
    ) {
        token0 = _token0;
        token1 = _token1;
        priceFeed0 = AggregatorV3Interface(_priceFeed0);
        priceFeed1 = AggregatorV3Interface(_priceFeed1);
    }

    /**
     * @dev Internal function to add liquidity to the pool.
     * @param amount0 Amount of token0 to add.
     * @param amount1 Amount of token1 to add.
     */
    function addLiquidity(uint256 amount0, uint256 amount1) internal {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        reserve0 += amount0;
        reserve1 += amount1;
    }

    /**
     * @dev External function to add liquidity in USD equivalent without enforcing ratio.
     * @param usdAmount Total USD value of liquidity to add.
     */
    function addLiquidityInUSD(uint256 usdAmount) external {
        // Fetch the current prices of token0 and token1 in USD
        uint256 price0 = uint256(getPrice(token0));
        uint256 price1 = uint256(getPrice(token1));

        // Calculate the amounts of token0 and token1 based on the USD value and their prices
        uint256 amount0 = (usdAmount * 10**18) / (2 * price0);
        uint256 amount1 = (usdAmount * 10**18) / (2 * price1);

        // Add liquidity to the pool without enforcing the ratio check
        addLiquidity(amount0, amount1);
    }

    /**
     * @dev Internal function to remove liquidity from the pool.
     * @param liquidity Total liquidity to remove.
     */
    function removeLiquidity(uint256 liquidity) internal {
        // Proportionate amounts to remove
        uint256 amount0 = reserve0 * liquidity / (reserve0 + reserve1);
        uint256 amount1 = reserve1 * liquidity / (reserve0 + reserve1);

        // Transfer the tokens back to the user
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);

        // Update the reserves
        reserve0 -= amount0;
        reserve1 -= amount1;
    }

    /**
     * @dev External function to remove liquidity in USD equivalent without enforcing ratio.
     * @param usdAmount Total USD value of liquidity to remove.
     */
    function removeLiquidityInUSD(uint256 usdAmount) external {
        // Fetch the current prices of token0 and token1 in USD
        uint256 price0 = uint256(getPrice(token0));
        uint256 price1 = uint256(getPrice(token1));

        // Calculate the amounts of token0 and token1 based on the USD value and their prices
        uint256 amount0 = (usdAmount * 10**18) / (2 * price0);
        uint256 amount1 = (usdAmount * 10**18) / (2 * price1);

        // Remove liquidity from the pool without enforcing the ratio check
        removeLiquidity(amount0 + amount1);
    }

    /**
     * @dev View function to get the current reserves of the pool.
     * @return (uint256, uint256) Reserves of token0 and token1.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    /**
     * @dev View function to get the current price of a token from the Chainlink price feed.
     * @param inputToken Address of the token to get the price for.
     * @return int Current price of the token in USD.
     */
    function getPrice(address inputToken) public view returns (int) {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");

        int price;
        if (inputToken == token0) {
            (,price,,,) = priceFeed0.latestRoundData();
        } else {
            (,price,,,) = priceFeed1.latestRoundData();
        }
        return price * 10**10; // Adjusting 8 decimals from Chainlink to 18 decimals
    }

    /**
     * @dev View function to get the price ratio between token0 and token1.
     * @return int Price ratio of token0 to token1.
     */
    function getPriceRatio() public view returns (int) {
        (,int price0,,,) = priceFeed0.latestRoundData();
        (,int price1,,,) = priceFeed1.latestRoundData();
        return (price0 * 10**10) * (10 ** 8) / (price1 * 10**10);  // Adjusting 8 decimals from Chainlink to 18 decimals
    }

   
     // @dev View function to calculate the output amount for a given input amount using the AMM formula.
     // @param amountIn Amount of the input token.
     // @param inputToken Address of the input token.
     // @return uint256 Amount of the output token.
     
    function getAmountOut(uint256 amountIn, address inputToken) public view returns (uint256 amountOut) {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");
        bool isInputToken0 = (inputToken == token0);
        uint256 inputReserve = isInputToken0 ? reserve0 : reserve1;
        uint256 outputReserve = isInputToken0 ? reserve1 : reserve0;
        uint256 amountInWithFee = amountIn * 997 / 1000;  // Applying a 0.3% fee
        amountOut = amountInWithFee * outputReserve / (inputReserve + amountInWithFee);
    }

    /**
     * @dev External function to swap tokens using USD value.
     * @param usdAmount Amount of USD to swap from inputToken to outputToken.
     * @param inputToken Address of the input token.
     */
    function swapInUSD(uint256 usdAmount, address inputToken) external {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");

        // Fetch the current prices of token0 and token1 in USD
        uint256 price0 = uint256(getPrice(token0));
        uint256 price1 = uint256(getPrice(token1));

        bool isInputToken0 = (inputToken == token0);
        address outputToken = isInputToken0 ? token1 : token0;
        uint256 inputPrice = isInputToken0 ? price0 : price1;

        // Calculate the amount of input tokens based on the USD value
        uint256 amountIn = (usdAmount * 10**18) / inputPrice;

        // Calculate the amount of output tokens using the AMM formula
        uint256 amountOut = getAmountOut(amountIn, inputToken);

        // Transfer input tokens from the user to the contract
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);

        // Transfer output tokens from the contract to the user
        IERC20(outputToken).transfer(msg.sender, amountOut);

        // Update the reserves
        if (isInputToken0) {
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else {
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }
    }
}
