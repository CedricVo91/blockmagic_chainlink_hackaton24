import json
from web3 import Web3

ganache_url = "HTTP://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))
chain_id = 1337

assert web3.is_connected()

if web3.is_connected():
    chain_id = web3.eth.chain_id
    print(f"The chain ID is: {chain_id}")
else:
    print("Connection failed.")


#set default account
web3.eth.default_account = web3.eth.accounts[0]
private_key = "187d5075981ffbcf0df88ec2985bad86f7a53dce190bea53ad18b1837c141b01"

with open("MockDaiTokenv4.json", "r") as file:
    mockDAI_json = json.load(file)


key = "/Users/cedi4/blockmagic_hackaton24/contracts/MockDAI.sol:MockDAI"

# get bytecode
bytecode = mockDAI_json["contracts"]["MockDAI.sol"]["MockDAI"]["evm"]["bytecode"]["object"]
#print(bytecode)

#get abi
abi = mockDAI_json["contracts"]["MockDAI.sol"]["MockDAI"]["abi"]

#print(abi)



#create contract in python
mockDAI = web3.eth.contract(abi = abi, bytecode = bytecode)
print(mockDAI)

#get nonce
nonce = web3.eth.get_transaction_count(web3.eth.default_account )
#print(nonce)


# Build transaction
transaction = mockDAI.constructor().build_transaction({
    'chainId': chain_id,
    'gas': 3000000,
    'gasPrice': web3.to_wei('1', 'gwei'),
    'nonce': nonce,
})

# Sign transaction
signed_txn = web3.eth.account.sign_transaction(transaction, private_key=private_key)


# Send transaction
try:
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
    print(tx_hash)
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    contract_address = tx_receipt.contractAddress
    print(f"Contract deployed at address: {contract_address}")
except Exception as e:
    print(f"Deployment failed: {e}")
