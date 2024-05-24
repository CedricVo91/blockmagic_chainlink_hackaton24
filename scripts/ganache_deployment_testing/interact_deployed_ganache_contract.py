import json
from web3 import Web3

ganache_url = "HTTP://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))
chain_id = 1337
assert web3.is_connected()

#set default account
web3.eth.default_account = web3.eth.accounts[0]
private_key = "187d5075981ffbcf0df88ec2985bad86f7a53dce190bea53ad18b1837c141b01"

with open("MockDaiTokenv4.json", "r") as file:
    mockDAI_json = json.load(file)

# Replace the contract address with the one from the deployment script
contract_address = "0x90732739eCA4c91163873fD68fC105f4F2b07271"

# get abi
abi = mockDAI_json["contracts"]["MockDAI.sol"]["MockDAI"]["abi"]

#create contract instance

mockDAI = web3.eth.contract(address = contract_address, abi=abi)

# Verify contract name, symbol, and total supply
try:
    name = mockDAI.functions.name().call()
    symbol = mockDAI.functions.symbol().call()
    total_supply = mockDAI.functions.totalSupply().call()

    print(f"Contract Name: {name}")
    print(f"Contract Symbol: {symbol}")
    print(f"Total Supply: {total_supply}")

    # Perform a token transfer
    receiver = "0x39D430DaAd22EB14304a57BCB15A42415AFB0a8F"  # replace with an appropriate address from Ganache
    amount = 100 * (10 ** 18)  # adjust the amount as needed

    # Build transaction for transfer
    nonce = web3.eth.get_transaction_count(web3.eth.default_account)
    transfer_txn = mockDAI.functions.transfer(receiver, amount).build_transaction({
        'chainId': 1337,
        'gas': 300000,
        'gasPrice': web3.to_wei('1', 'gwei'),
        'nonce': nonce,
    })

    # Sign and send the transaction
    signed_txn = web3.eth.account.sign_transaction(transfer_txn, private_key=private_key)
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)

    print(f"Transfer Transaction Hash: {tx_hash.hex()}")

    # Wait for the transaction receipt
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Transfer Transaction Receipt: {tx_receipt}")

    # Verify the balance of the receiver
    receiver_balance = mockDAI.functions.balanceOf(receiver).call()
    print(f"Receiver Balance: {receiver_balance}")

except Exception as e:
    print(f"Error interacting with the contract: {e}")


# Check balance of the sender
sender_balance = mockDAI.functions.balanceOf(web3.eth.default_account).call()
print(f"Sender Balance: {sender_balance}")


"""
# Test approve and transferFrom
spender = "0x39d430daad22eb14304a57bcb15a42415afb0a8f"  # another account from Ganache
approval_amount = 50 * (10 ** 18)  # 50 DAI

# Approve the spender to spend 50 DAI
approve_txn = mockDAI.functions.approve(spender, approval_amount).build_transaction({
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
transfer_from_txn = mockDAI.functions.transferFrom(
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
spender_private_key = "your_spender_private_key_here"  # Replace with actual private key
signed_transfer_from_txn = web3.eth.account.sign_transaction(transfer_from_txn, private_key=spender_private_key)
transfer_from_tx_hash = web3.eth.send_raw_transaction(signed_transfer_from_txn.rawTransaction)
print(f"TransferFrom Transaction Hash: {transfer_from_tx_hash.hex()}")

# Wait for the transaction receipt
transfer_from_tx_receipt = web3.eth.wait_for_transaction_receipt(transfer_from_tx_hash)
print(f"TransferFrom Transaction Receipt: {transfer_from_tx_receipt}")

# Verify balances again
sender_balance_after = mockDAI.functions.balanceOf(web3.eth.default_account).call()
receiver_balance_after = mockDAI.functions.balanceOf(receiver).call()
spender_balance_after = mockDAI.functions.balanceOf(spender).call()

print(f"Sender Balance After: {sender_balance_after}")
print(f"Receiver Balance After: {receiver_balance_after}")
print(f"Spender Balance After: {spender_balance_after}")
"""