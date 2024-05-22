
from web3 import Web3

ganache_url = "HTTP://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))
print("connected" if web3.is_connected() is True else print("Not worked"))

account_1 = "0xe98da224db372e29edEb64C39F4f74Af4eAFDBd9"
account_2 = "0x66e97374ee11673D27a6136c6d22C8B9fB764204"

private_key = "104cf732d5e23190f7588e4bc1d6c9ba25376fb497d0709d34e7dc4c79907976"

#get the nonce
nonce = web3.eth.get_transaction_count(account_1)

#build a transaction
tx = {"nonce":nonce,
      "to": account_2,
      "value": web3.to_wei(1, "ether"),
      "gas": 2000000,
      "gasPrice": web3.to_wei("50", "gwei")}

signed_tx = web3.eth.account.sign_transaction(tx, private_key)
tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
print(web3.to_hex(tx_hash))




#sign transaction
#send transaction
#get transaction hash
