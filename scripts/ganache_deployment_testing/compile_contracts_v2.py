# * Goal of the script: compile my sol contracts and saved them as json
# * I need these json files to then interact with the ganache blockchain

import json
from solcx import compile_standard, compile_files, install_solc, set_solc_version
import os

# Install specific version of solc
install_solc('0.8.19')
set_solc_version('0.8.19')

# * collin's approach to get byte code and abi

#read solidity file -> works
with open("../../contracts/MockDAI.sol", "r") as file:
    mockDAI_file = file.read()

#does not work because of the open zeppelin bullshit import...

compiled_sol = compile_standard({
        "language": "Solidity",
        "sources": {"MockDAI.sol": {"content": mockDAI_file}},
        "settings": {
            "outputSelection": {
                "*": {"*": ["abi", "metadata", "evm.bytecode","evm.sourceMap"]}
            }
        }
    },
       solc_version='0.8.19',
    )

print(compiled_sol)

"""
with open("MockDaiTokenv5.json", "w") as file:
    json.dump(compiled_sol, file)



# get bytecode
bytecode = compiled_sol["contracts"]["MockDAI.sol"]["MockDAI"]["evm"]["bytecode"]["object"]
print(bytecode)

#get abi
abi = compiled_sol["contracts"]["MockDAI.sol"]["MockDAI"]["abi"]
print(abi)
"""
