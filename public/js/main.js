const contractAddress = "0xAd90E94ee8489A563F8FD41c75F56d1b97556414";
const contractABI = [
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			}
		],
		"name": "allowance",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "approve",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "account",
				"type": "address"
			}
		],
		"name": "balanceOf",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalSupply",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "recipient",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "transfer",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "recipient",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			}
		],
		"name": "transferFrom",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	}
];

let web3;
let contract;
let accounts;

async function connectWallet() {
    const statusDiv = document.getElementById('status');
    try {
        if (typeof window.ethereum !== 'undefined') {
            web3 = new Web3(window.ethereum);
            accounts = await ethereum.request({ method: 'eth_requestAccounts' });
            if (accounts.length === 0) {
                throw new Error('No accounts found. Please create an account in your wallet.');
            }
            wallet = accounts[0];
            contract = new web3.eth.Contract(contractABI, contractAddress);
            document.getElementById('walletAddress').textContent = wallet;

            const balance = await web3.eth.getBalance(wallet);
            const balanceInBCH = web3.utils.fromWei(balance, 'ether');
            document.getElementById('walletBalance').textContent = balanceInBCH;

            statusDiv.textContent = 'Wallet connected successfully!';
        } else {
            throw new Error('MetaMask wallet not detected. Please install MetaMask.');
        }
    } catch (error) {
        statusDiv.textContent = `Error connecting wallet: ${error.message}`;
        console.error('Wallet connection error:', error);
    }
}

async function addLiquidity() {
    const statusDiv = document.getElementById('status');
    if (!wallet) {
        statusDiv.textContent = 'Please connect your wallet first.';
        return;
    }

    const bchAmount = document.getElementById('bchAmount').value;
    const tokenAmount = document.getElementById('tokenAmount').value;

    statusDiv.textContent = `Adding ${bchAmount} BCH and ${tokenAmount} Xolos $RMZ tokens to the liquidity pool...`;

    try {
        await contract.methods.addLiquidity(tokenAmount).send({ from: wallet, value: web3.utils.toWei(bchAmount, 'ether') });
        statusDiv.textContent = `Successfully added liquidity: ${bchAmount} BCH and ${tokenAmount} Xolos $RMZ tokens.`;
    } catch (error) {
        statusDiv.textContent = `Error: ${error.message}`;
        console.error('Add liquidity error:', error);
    }
}

async function swapBCHForToken() {
    const statusDiv = document.getElementById('status');
    if (!wallet) {
        statusDiv.textContent = 'Please connect your wallet first.';
        return;
    }

    const bchAmount = document.getElementById('bchAmount').value;
    const minTokens = document.getElementById('minTokens').value;

    statusDiv.textContent = `Swapping ${bchAmount} BCH for at least ${minTokens} Xolos $RMZ tokens...`;

    try {
        await contract.methods.swapBCHForToken(minTokens).send({ from: wallet, value: web3.utils.toWei(bchAmount, 'ether') });
        statusDiv.textContent = `Successfully swapped ${bchAmount} BCH for at least ${minTokens} Xolos $RMZ tokens.`;
    } catch (error) {
        statusDiv.textContent = `Error: ${error.message}`;
        console.error('Swap error:', error);
    }
}
