# * Goal of the script: compile my sol contracts and saved them as json
# * I need these json files to then interact with the ganache blockchain

import json
from solcx import compile_files, install_solc, set_solc_version
import os

# Install specific version of solc
install_solc('0.8.20')
set_solc_version('0.8.20')

# Define the path to your Solidity files and node_modules for OpenZeppelin contracts
contracts_folder_path = os.path.join(os.path.dirname(__file__), '..', 'contracts')
node_modules_path = os.path.join(os.path.dirname(__file__), '..', 'node_modules')

# Path to your MockToken Solidity file
mock_token_file = os.path.join(contracts_folder_path, 'MockDAI.sol')

# Set the remappings for OpenZeppelin contracts
import_remappings = [
    f"@openzeppelin/={node_modules_path}/@openzeppelin/"
]

# Compile MockToken with import remappings
compiled_mock_token = compile_files([mock_token_file], import_remappings=import_remappings)

# Print available keys for debugging
print("Compiled contract keys:", compiled_mock_token.keys())

# Extract the correct contract key
contract_key = next(iter(compiled_mock_token))

# Extract ABI and Bytecode
mock_token_contract = compiled_mock_token[contract_key]
mock_token_abi = mock_token_contract['abi']
mock_token_bytecode = mock_token_contract['bin']

# Save MockToken ABI and Bytecode
with open('MockDaiToken.json', 'w') as f:
    json.dump({
        'abi': mock_token_abi,
        'bytecode': mock_token_bytecode
    }, f)

print("MockToken compiled and saved as JSON file")
