// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FixedPriceLiquidityPool is ReentrancyGuard {
    IERC20 public immutable token;
    address public immutable owner;
    uint256 public tokenPriceInBCH; // Fixed price in wei

    mapping(address => uint256) public liquidity;

    event LiquidityAdded(address indexed provider, uint256 amountBCH, uint256 amountToken);
    event LiquidityRemoved(address indexed provider, uint256 amountBCH, uint256 amountToken);
    event Swapped(address indexed swapper, uint256 amountBCH, uint256 amountToken, bool isBCHToToken);

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
        tokenPriceInBCH = 6.73 ether; // Fixed price of 6.73 BCH per 1 Xolos $RMZ token
    }

    function addLiquidity(uint256 tokenAmount) external payable nonReentrant {
        require(msg.value > 0 && tokenAmount > 0, "Insufficient amounts");
        
        liquidity[msg.sender] += msg.value;
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        emit LiquidityAdded(msg.sender, msg.value, tokenAmount);
    }

    function removeLiquidity(uint256 amountBCH) external nonReentrant {
        require(liquidity[msg.sender] >= amountBCH, "Insufficient liquidity");

        uint256 tokenAmount = (amountBCH * token.balanceOf(address(this))) / address(this).balance;

        liquidity[msg.sender] -= amountBCH;

        (bool success, ) = payable(msg.sender).call{value: amountBCH}("");
        require(success, "BCH transfer failed");

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit LiquidityRemoved(msg.sender, amountBCH, tokenAmount);
    }

    function swapBCHForToken() external payable nonReentrant {
        require(msg.value > 0, "BCH amount must be greater than zero");

        uint256 tokenAmount = (msg.value * 1e18) / tokenPriceInBCH;
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient token balance");

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit Swapped(msg.sender, msg.value, tokenAmount, true);
    }

    function swapTokenForBCH(uint256 tokenAmount) external nonReentrant {
        require(tokenAmount > 0, "Token amount must be greater than zero");

        uint256 bchAmount = (tokenAmount * tokenPriceInBCH) / 1e18;
        require(address(this).balance >= bchAmount, "Insufficient BCH balance");

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        (bool success, ) = payable(msg.sender).call{value: bchAmount}("");
        require(success, "BCH transfer failed");

        emit Swapped(msg.sender, bchAmount, tokenAmount, false);
    }

    function updateTokenPrice(uint256 newPrice) external {
        require(msg.sender == owner, "Only owner can update token price");
        tokenPriceInBCH = newPrice;
    }
}
