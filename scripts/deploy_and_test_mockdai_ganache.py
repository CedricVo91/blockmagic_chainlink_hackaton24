import json
from web3 import Web3

ganache_url = "HTTP://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))

assert web3.is_connected()

#set default account
web3.eth.default_account = web3.eth.accounts[0]

with open("MockDaiToken.json", "r") as file:
    mockdai_json = json.load(file)

abi = mockdai_json["abi"]
bytecode = mockdai_json["bytecode"]

# Print ABI to verify the constructor
print("ABI:", abi)

# Deploy the contract
MockDAI = web3.eth.contract(abi=abi, bytecode=bytecode)
try:
    tx_hash = MockDAI.constructor().transact()  # No parameters
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    contract_address = tx_receipt.contractAddress
    print(f"Contract deployed at address: {contract_address}")
except Exception as e:
    print(f"Deployment failed: {e}")
