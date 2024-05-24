from web3 import Web3
import json

# Connect to local Ethereum node
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

# Load your contract ABI
with open('SimpleDEX.json', 'r') as f:
    abi = json.load(f)

# Contract address (replace with your deployed contract address)
contract_address = '0xYourContractAddress'

# Create contract instance
dex_contract = w3.eth.contract(address=contract_address, abi=abi)

# Add liquidity
def add_liquidity(account, private_key, amount1, amount2):
    nonce = w3.eth.getTransactionCount(account)
    txn = dex_contract.functions.addLiquidity(amount1, amount2).buildTransaction({
        'chainId': 1,
        'gas': 2000000,
        'gasPrice': w3.toWei('50', 'gwei'),
        'nonce': nonce,
    })
    signed_txn = w3.eth.account.signTransaction(txn, private_key=private_key)
    w3.eth.sendRawTransaction(signed_txn.rawTransaction)

# Swap tokens
def swap(account, private_key, amount1):
    nonce = w3.eth.getTransactionCount(account)
    txn = dex_contract.functions.swap(amount1).buildTransaction({
        'chainId': 1,
        'gas': 2000000,
        'gasPrice': w3.toWei('50', 'gwei'),
        'nonce': nonce,
    })
    signed_txn = w3.eth.account.signTransaction(txn, private_key=private_key)
    w3.eth.sendRawTransaction(signed_txn.rawTransaction)

# Example usage
account = '0xYourAccount'
private_key = 'YourPrivateKey'
add_liquidity(account, private_key, 100, 200)
swap(account, private_key, 50)
