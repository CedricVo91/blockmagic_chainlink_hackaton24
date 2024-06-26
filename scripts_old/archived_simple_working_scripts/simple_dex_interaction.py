# * test my simple dex on ganache

from web3 import Web3
import json
import os

# connect to Ganache
ganache_url = "HTTP://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url))

# check connection
assert web3.is_connected() #returns True if connected

# Set default account (replace with your account from Ganache)
web3.eth.defaultAccount = web3.eth.accounts[0]
private_key = "104cf732d5e23190f7588e4bc1d6c9ba25376fb497d0709d34e7dc4c79907976"

#test my simple dex on real testnet using real tokens

#research and start writing the factor contract
