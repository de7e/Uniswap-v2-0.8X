// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract MyDex {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public uniswapRouter;
    address public usdtAddress; // USDT 地址

    constructor(address _uniswapRouter, address _usdtAddress) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        usdtAddress = _usdtAddress;
    }

    /**
     * @dev 卖出ETH，兑换成 buyToken
     * @param buyToken 兑换的目标代币地址
     * @param minBuyAmount 要求最低兑换到的 buyToken 数量
     */
    function sellETH(address buyToken, uint256 minBuyAmount) external payable {
        require(msg.value > 0, "Must send ETH to sell");
        require(minBuyAmount > 0, "Min buy amount must be greater than 0");
        require(buyToken != address(0), "Buy token address must not be zero");

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = buyToken;
        IERC20(buyToken).approve(address(uniswapRouter), minBuyAmount);

        uniswapRouter.swapExactETHForTokens{value: msg.value}(minBuyAmount, path, msg.sender, block.timestamp + 1000);
    }

    /**
     * @dev 买入ETH，用 sellToken 兑换
     * @param sellToken 出售的代币地址
     * @param sellAmount 出售的代币数量
     * @param minBuyAmount 要求最低兑换到的ETH数量
     */
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external {
        require(sellAmount > 0, "Must specify amount to sell");

        IERC20(sellToken).safeTransferFrom(msg.sender, address(this), sellAmount);

        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = uniswapRouter.WETH();

        IERC20(sellToken).approve(address(uniswapRouter), sellAmount);

        uniswapRouter.swapExactTokensForETH(sellAmount, minBuyAmount, path, msg.sender, block.timestamp);
    }

    // 提取合约中的 ETH
    function withdrawETH() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    // 提取合约中的代币
    function withdrawTokens(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, balance);
    }
}
