# * Goal of the script: compile my sol contracts and saved them as json
# * I need these json files to then interact with the ganache blockchain

import json
from solcx import compile_standard, compile_files, install_solc, set_solc_version
import os

# Install specific version of solc
install_solc('0.8.19')
set_solc_version('0.8.19')

# * chat gpt's approach to get byte code and abi

# Define the path to your Solidity files and node_modules for OpenZeppelin contracts
contracts_folder_path = os.path.join(os.path.dirname(__file__), '..', 'contracts')
node_modules_path = os.path.join(os.path.dirname(__file__), '..', 'node_modules')

# Path to your MockToken Solidity file
mock_token_file = os.path.join(contracts_folder_path, 'MockDAI.sol')

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

#print(compiled_mock_token)
contract_key = next(iter(compiled_mock_token))

# Extract ABI and Bytecode
mock_token_contract = compiled_mock_token[contract_key]
mock_token_abi = mock_token_contract['abi']
mock_token_bytecode = mock_token_contract['bin']

print(mock_token_bytecode)

with open("../archived_to_be_deleted_docs/MockDaiTokenv3.json", "w") as file:
    json.dump(compiled_mock_token, file)


