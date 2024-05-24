import json
from solcx import compile_standard, install_solc, set_solc_version
import os

# Install specific version of solc
install_solc('0.8.19')
set_solc_version('0.8.19')

# Define the path to your Solidity files and node_modules for OpenZeppelin contracts
contracts_folder_path = os.path.join(os.path.dirname(__file__), '..', '..', 'contracts')
node_modules_path = os.path.join(os.path.dirname(__file__), '..', '..', 'node_modules')

# Path to your MockToken Solidity file
mock_token_file = os.path.join(contracts_folder_path, 'MockDAI.sol')

# Set the remappings for OpenZeppelin contracts
import_remappings = [
    f"@openzeppelin/={node_modules_path}/@openzeppelin/"
]

# Read Solidity file
with open(mock_token_file, "r") as file:
    mockDAI_file = file.read()

# Compile Solidity file with remappings
compiled_sol = compile_standard({
    "language": "Solidity",
    "sources": {"MockDAI.sol": {"content": mockDAI_file}},
    "settings": {
        "remappings": import_remappings,
        "outputSelection": {
            "*": {"*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]}
        }
    }
}, solc_version='0.8.19')

# Print compiled output
print(compiled_sol)

# Save compiled output to a file
with open("MockDaiTokenv4.json", "w") as file:
    json.dump(compiled_sol, file)

# Extract and print ABI and Bytecode
bytecode = compiled_sol["contracts"]["MockDAI.sol"]["MockDAI"]["evm"]["bytecode"]["object"]
print(bytecode)

abi = compiled_sol["contracts"]["MockDAI.sol"]["MockDAI"]["abi"]
print(abi)
