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
web3.eth.default_account = web3.eth.accounts[0]  # Sender account
private_key = ""  # Sender's private key

receiver = web3.to_checksum_address("0x39d430daad22eb14304a57bcb15a42415afb0a8f")  # Receiver account
spender = web3.to_checksum_address("0xA11a02320955756298146ACFd464882453570953")  # Third Ganache account address acting as the spender
spender_private_key = "65c92198487de1785d9c9b039c3456d66b48b1a22b01ca1c2afe7de7a0d791c4"  # Spender's private key

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

# Build transaction for contract deployment
transaction = mockDAI.constructor().build_transaction({
    'chainId': chain_id,
    'gas': 3000000,
    'gasPrice': web3.to_wei('1', 'gwei'),
    'nonce': nonce,
})

# Sign transaction for contract deployment
signed_txn = web3.eth.account.sign_transaction(transaction, private_key=private_key)

# Send transaction for contract deployment
try:
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
    print(tx_hash)
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    contract_address = tx_receipt.contractAddress
    print(f"Contract deployed at address: {contract_address}")
except Exception as e:
    print(f"Deployment failed: {e}")

# Interacting with deployed contract
mockDAI_contract = web3.eth.contract(address=contract_address, abi=abi)

# Check balance of the sender
sender_balance = mockDAI_contract.functions.balanceOf(web3.eth.default_account).call()
print(f"Sender Balance: {sender_balance}")

# Test approve and transferFrom
approval_amount = 50 * (10 ** 18)  # 50 DAI

# Approve the spender to spend 50 DAI
approve_txn = mockDAI_contract.functions.approve(spender, approval_amount).build_transaction({
    'chainId': chain_id,
    'gas': 200000,
    'gasPrice': web3.to_wei('1', 'gwei'),
    'nonce': web3.eth.get_transaction_count(web3.eth.default_account)
})

signed_approve_txn = web3.eth.account.sign_transaction(approve_txn, private_key=private_key)
approve_tx_hash = web3.eth.send_raw_transaction(signed_approve_txn.rawTransaction)
print(f"Approve Transaction Hash: {approve_tx_hash.hex()}")

# Wait for the transaction receipt
approve_tx_receipt = web3.eth.wait_for_transaction_receipt(approve_tx_hash)
print(f"Approve Transaction Receipt: {approve_tx_receipt}")

# TransferFrom (spender transfers from default account to receiver)
transfer_from_txn = mockDAI_contract.functions.transferFrom(
    web3.eth.default_account,
    receiver,
    20 * (10 ** 18)  # 20 DAI
).build_transaction({
    'chainId': chain_id,
    'gas': 200000,
    'gasPrice': web3.to_wei('1', 'gwei'),
    'nonce': web3.eth.get_transaction_count(spender)
})

# Sign and send the transaction from the spender's account
signed_transfer_from_txn = web3.eth.account.sign_transaction(transfer_from_txn, private_key=spender_private_key)
transfer_from_tx_hash = web3.eth.send_raw_transaction(signed_transfer_from_txn.rawTransaction)
print(f"TransferFrom Transaction Hash: {transfer_from_tx_hash.hex()}")

# Wait for the transaction receipt
transfer_from_tx_receipt = web3.eth.wait_for_transaction_receipt(transfer_from_tx_hash)
print(f"TransferFrom Transaction Receipt: {transfer_from_tx_receipt}")

# Verify balances again
sender_balance_after = mockDAI_contract.functions.balanceOf(web3.eth.default_account).call()
receiver_balance_after = mockDAI_contract.functions.balanceOf(receiver).call()
spender_balance_after = mockDAI_contract.functions.balanceOf(spender).call()

print(f"Sender Balance After: {sender_balance_after}")
print(f"Receiver Balance After: {receiver_balance_after}")
print(f"Spender Balance After: {spender_balance_after}")
