// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {WETH9} from "../src/WETH9.sol";
import {ERC20Mintable} from "../src/ERC20Mintable.sol";
import {MyDex} from "../src/MyDex/MyDex.sol";

contract UniswapV2Router02Test is Test {
    UniswapV2Router02 public uniswapv2router02;
    UniswapV2Factory public uniswapv2factory;
    ERC20Mintable token0;
    ERC20Mintable token1;
    WETH9 public weth;
    MyDex public mydex;

    Account public owner = makeAccount("owner");
    Account public user = makeAccount("user");
    Account public tokenA = makeAccount("tokenA");
    Account public tokenB = makeAccount("tokenB");

    function setUp() public {
        weth = new WETH9();

        uniswapv2factory = new UniswapV2Factory(owner.addr);
        uniswapv2router02 = new UniswapV2Router02(address(uniswapv2factory), address(weth));

        vm.startPrank(tokenA.addr);
        token0 = new ERC20Mintable(tokenA.addr, "Token A", "TKNA");
        token0.approve(tokenA.addr, 100 ether);
        token0.mint(tokenA.addr, 10 ether);
        token0.transfer(user.addr, 1 ether);
        vm.stopPrank();
        vm.startPrank(tokenB.addr);
        token1 = new ERC20Mintable(tokenB.addr, "Token B", "TKNB");
        token1.approve(tokenB.addr, 100 ether);
        token1.mint(tokenB.addr, 10 ether);
        token1.transfer(user.addr, 1 ether);
        vm.stopPrank();

        mydex = new MyDex(address(uniswapv2router02), address(token0));
    }

    function testAddLiquidity() public {
        vm.startPrank(user.addr);
        assertEq(token0.balanceOf(address(user.addr)), 1 ether);
        assertEq(token1.balanceOf(address(user.addr)), 1 ether);
        token0.approve(address(uniswapv2router02), 1 ether);
        token1.approve(address(uniswapv2router02), 1 ether);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = uniswapv2router02.addLiquidity(
            address(token0), address(token1), 1 ether, 1 ether, 1 ether, 1 ether, user.addr, block.timestamp + 1000
        );
        assertEq(amountA, 1 ether);
        assertEq(amountB, 1 ether);
        assertEq(liquidity, 1 ether - 1000);
        assertEq(token0.balanceOf(address(user.addr)), 0);
        assertEq(token1.balanceOf(address(user.addr)), 0);

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        testAddLiquidity();
        vm.startPrank(user.addr);
        assertEq(token0.balanceOf(address(user.addr)), 0);
        assertEq(token1.balanceOf(address(user.addr)), 0);
        token0.approve(address(uniswapv2router02), 1 ether);
        token1.approve(address(uniswapv2router02), 1 ether);

        (uint256 amountA, uint256 amountB) = uniswapv2router02.removeLiquidity(
            address(token0), address(token1), 1 ether, 1 ether, 1 ether, user.addr, block.timestamp + 1000
        );

        assertEq(amountA, 1 ether);
        assertEq(amountB, 1 ether);
        assertEq(token0.balanceOf(address(user.addr)), 1 ether);
        assertEq(token1.balanceOf(address(user.addr)), 1 ether);
    }

    function testSellETH() public {
        weth.deposit{value: 10 ether}();
        vm.prank(tokenA.addr);
        token0.mint(address(this), 10 ether);

        token0.approve(address(uniswapv2router02), 10 ether);
        weth.approve(address(uniswapv2router02), 10 ether);

        // 1. add liquidity
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = uniswapv2router02.addLiquidityETH{value: 10 ether}(
            address(token0), 10 ether, 1 ether, 1 ether, user.addr, block.timestamp
        );
        assertEq(amountToken, 10 ether);
        assertEq(amountETH, 10 ether);
        assertEq(liquidity, 10 ether - 1000);
        // 2. sell ETH
        mydex.sellETH{value: 2 ether}(address(token0), 1 ether);
        // assertEq(token0.balanceOf(address(user.addr)), 1 ether);
        // assertEq(token1.balanceOf(address(user.addr)), 0);
    }
}