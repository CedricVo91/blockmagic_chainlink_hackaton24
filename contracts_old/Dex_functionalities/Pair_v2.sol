// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pair {
    address public token0;
    address public token1;
    uint256 public reserve0;
    uint256 public reserve1;

    AggregatorV3Interface internal priceFeed0;
    AggregatorV3Interface internal priceFeed1;

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

    function addLiquidity(uint256 amount0, uint256 amount1) external {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address (this), amount1);
        reserve0 += amount0;
        reserve1 += amount1;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function getPrice(address inputToken) public view returns (int) {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");

        if (inputToken == token0) {
            (,int price,,,) = priceFeed0.latestRoundData();
            return price;
        } else {
            (,int price,,,) = priceFeed1.latestRoundData();
            return price;
        }
    }

    function getPriceRatio() public view returns (int) {
        (,int price0,,,) = priceFeed0.latestRoundData();
        (,int price1,,,) = priceFeed1.latestRoundData();
        return price0 * (10 ** 8) / price1;  // Assuming price feeds have 8 decimals
    }

    function getAmountOut(uint256 amountIn, address inputToken) public view returns (uint256 amountOut) {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");
        bool isInputToken0 = (inputToken == token0);
        uint256 inputReserve = isInputToken0 ? reserve0 : reserve1;
        uint256 outputReserve = isInputToken0 ? reserve1 : reserve0;
        uint256 amountInWithFee = amountIn * 997 / 1000;
        amountOut = amountInWithFee * outputReserve / (inputReserve + amountInWithFee);
    }

    function swap(uint256 amountIn, address inputToken) external {
        require(inputToken == token0 || inputToken == token1, "Invalid input token");
        bool isInputToken0 = inputToken == token0;
        uint256 amountOut = getAmountOut(amountIn, inputToken);
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);
        if (isInputToken0) {
            IERC20(token1).transfer(msg.sender, amountOut);
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else {
            IERC20(token0).transfer(msg.sender, amountOut);
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }
    }
}
