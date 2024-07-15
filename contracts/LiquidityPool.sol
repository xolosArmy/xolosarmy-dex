// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    address public token;
    address public owner;
    uint256 public totalLiquidity;

    mapping(address => uint256) public liquidity;

    event LiquidityAdded(address indexed provider, uint256 amountBCH, uint256 amountToken);
    event LiquidityRemoved(address indexed provider, uint256 amountBCH, uint256 amountToken);
    event Swapped(address indexed swapper, uint256 amountIn, uint256 amountOut);

    constructor(address _token) {
        token = _token;
        owner = msg.sender;
    }

    function addLiquidity(uint256 tokenAmount) public payable returns (uint256) {
        require(msg.value > 0 && tokenAmount > 0, "Insufficient amounts");

        liquidity[msg.sender] += msg.value;
        totalLiquidity += msg.value;

        require(IERC20(token).transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        emit LiquidityAdded(msg.sender, msg.value, tokenAmount);

        return msg.value;
    }

    function removeLiquidity(uint256 amount) public returns (uint256, uint256) {
        require(liquidity[msg.sender] >= amount, "Insufficient liquidity");

        uint256 tokenAmount = (amount * IERC20(token).balanceOf(address(this))) / address(this).balance;
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        payable(msg.sender).transfer(amount);
        require(IERC20(token).transfer(msg.sender, tokenAmount), "Token transfer failed");

        emit LiquidityRemoved(msg.sender, amount, tokenAmount);

        return (amount, tokenAmount);
    }

    function swapBCHForToken(uint256 minTokens) public payable {
    require(msg.value > 0, "BCH amount must be greater than zero");

    uint256 tokenAmount = getEquivalentTokenAmount(msg.value);
    require(tokenAmount >= minTokens, "Insufficient output amount");

    // Transfer tokens from contract to sender
    IERC20(token).transfer(msg.sender, tokenAmount);

    emit Swapped(msg.sender, msg.value, tokenAmount);
}

function getEquivalentTokenAmount(uint256 bchAmount) internal view returns (uint256) {
    uint256 tokenReserve = IERC20(token).balanceOf(address(this));
    uint256 bchReserve = address(this).balance;
    // Use a simple formula for conversion, e.g., constant product formula
    return (bchAmount * tokenReserve) / bchReserve;
}


    function swapTokenForBCH(uint256 tokenAmount, uint256 minBCH) public {
        require(tokenAmount > 0, "Insufficient token amount");

        uint256 bchAmount = (tokenAmount * address(this).balance) / IERC20(token).balanceOf(address(this));
        require(bchAmount >= minBCH, "Insufficient output amount");

        require(IERC20(token).transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        payable(msg.sender).transfer(bchAmount);

        emit Swapped(msg.sender, tokenAmount, bchAmount);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
