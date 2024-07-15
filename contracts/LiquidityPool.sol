// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OptimizedLiquidityPool is ReentrancyGuard {
    IERC20 public immutable token;
    address public immutable owner;
    uint256 public totalLiquidity;

    mapping(address => uint256) public liquidity;

    uint256 private constant PRECISION = 1e18;

    event LiquidityAdded(address indexed provider, uint256 amountBCH, uint256 amountToken);
    event LiquidityRemoved(address indexed provider, uint256 amountBCH, uint256 amountToken);
    event Swapped(address indexed swapper, uint256 amountIn, uint256 amountOut, bool isBCHToToken);

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    function addLiquidity(uint256 tokenAmount) external payable nonReentrant returns (uint256) {
        require(msg.value > 0 && tokenAmount > 0, "Insufficient amounts");
        
        uint256 liquidityMinted = msg.value;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        emit LiquidityAdded(msg.sender, msg.value, tokenAmount);
        return liquidityMinted;
    }

    function removeLiquidity(uint256 amount) external nonReentrant returns (uint256, uint256) {
        require(liquidity[msg.sender] >= amount, "Insufficient liquidity");

        uint256 tokenAmount = (amount * token.balanceOf(address(this))) / address(this).balance;
        
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "BCH transfer failed");

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit LiquidityRemoved(msg.sender, amount, tokenAmount);
        return (amount, tokenAmount);
    }

    function swapBCHForToken(uint256 minTokens) external payable nonReentrant {
        uint256 bchAmount = msg.value;
        require(bchAmount > 0, "BCH amount must be greater than zero");

        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 bchReserve = address(this).balance - bchAmount;
        require(bchReserve > 0 && tokenReserve > 0, "Insufficient liquidity");

        uint256 tokenAmount = (bchAmount * tokenReserve * PRECISION) / ((bchReserve * PRECISION) + (bchAmount * PRECISION));
        require(tokenAmount >= minTokens, "Insufficient output amount");

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit Swapped(msg.sender, bchAmount, tokenAmount, true);
    }

    function swapTokenForBCH(uint256 tokenAmount, uint256 minBCH) external nonReentrant {
        require(tokenAmount > 0, "Insufficient token amount");

        uint256 bchReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 bchAmount = (tokenAmount * bchReserve * PRECISION) / ((tokenReserve * PRECISION) + (tokenAmount * PRECISION));

        require(bchAmount >= minBCH, "Insufficient output amount");
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        (bool success, ) = payable(msg.sender).call{value: bchAmount}("");
        require(success, "BCH transfer failed");

        emit Swapped(msg.sender, tokenAmount, bchAmount, false);
    }
}
