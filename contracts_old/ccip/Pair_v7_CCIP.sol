// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./LPToken.sol";

contract Pair is CCIPReceiver {
    address public token0;
    address public token1;
    LPToken public lpToken;

    uint256 public reserve0;
    uint256 public reserve1;

    AggregatorV3Interface internal priceFeed0;
    AggregatorV3Interface internal priceFeed1;

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity, uint256 reserve0, uint256 reserve1);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity, uint256 reserve0, uint256 reserve1);
    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, string text);

    bytes32 private s_lastReceivedMessageId;
    string private s_lastReceivedText;

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
    }

    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text)
    {
        return (s_lastReceivedMessageId, s_lastReceivedText);
    }


    function addLiquidity(uint256 amount0, uint256 amount1) internal {
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
        require(liquidity > 0, "Insufficient liquidity");

        uint256 amount0 = liquidity * reserve0 / lpToken.totalSupply();
        uint256 amount1 = liquidity * reserve1 / lpToken.totalSupply();

        require(amount0 > 0 && amount1 > 0, "Insufficient liquidity removed");

        lpToken.burn(msg.sender, liquidity);

        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);

        reserve0 -= amount0;
        reserve1 -= amount1;

        emit LiquidityRemoved(msg.sender, amount0, amount1, liquidity, reserve0, reserve1);
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

        // Calculate the liquidity to remove
        uint256 liquidity = min(amount0 * lpToken.totalSupply() / reserve0, amount1 * lpToken.totalSupply() / reserve1);

        // Remove liquidity from the pool
        removeLiquidity(liquidity);
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

    /**
     * @dev View function to get the price of token0 in terms of token1 using the AMM formula.
     * @return uint256 Price of token0 in terms of token1.
     */
    function getDAIperLinkOurDEXPrice() public view returns (uint256) {
        require(reserve0 > 0 && reserve1 > 0, "Reserves are not set");
        return (reserve1 * 10**18) / reserve0; // Price of token0 in terms of token1
    }

    /**
     * @dev View function to get the current market price ratio of token0 to token1 using Chainlink price feeds.
     * @return uint256 Market price ratio of token0 to token1.
     */
    function getDAIperLinkMarketPrice() public view returns (uint256) {
        (,int price0,,,) = priceFeed0.latestRoundData();
        (,int price1,,,) = priceFeed1.latestRoundData();
        return (uint256(price0) * 10**18) / uint256(price1); // Market price of token0 in terms of token1
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
