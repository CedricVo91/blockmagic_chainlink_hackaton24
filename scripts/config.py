"""
Configuration file for deployment and testing scripts
DO NOT commit this file with real values - use environment variables for production
"""

import os
from typing import Dict

class NetworkConfig:
    """Network configuration settings"""

    # Ganache Local Network
    GANACHE_RPC_URL = os.getenv("GANACHE_RPC_URL", "http://127.0.0.1:8545")

    # Sepolia Testnet
    SEPOLIA_RPC_URL = os.getenv("SEPOLIA_RPC_URL", "https://sepolia.infura.io/v3/YOUR_INFURA_KEY")

    # Arbitrum Sepolia
    ARBITRUM_SEPOLIA_RPC_URL = os.getenv("ARBITRUM_SEPOLIA_RPC_URL", "https://sepolia-rollup.arbitrum.io/rpc")

    # Private keys (NEVER commit real values)
    # Use environment variables: export PRIVATE_KEY="your_key_here"
    PRIVATE_KEY = os.getenv("PRIVATE_KEY", "")

    # Validate private key is set
    @staticmethod
    def validate_private_key():
        if not NetworkConfig.PRIVATE_KEY or NetworkConfig.PRIVATE_KEY == "":
            raise ValueError(
                "Private key not set! Please set PRIVATE_KEY environment variable.\n"
                "Example: export PRIVATE_KEY='your_private_key_here'"
            )


class ContractAddresses:
    """Known contract addresses for different networks"""

    SEPOLIA = {
        "ccip_router": "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59",
        "link": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
        "usdc": "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
        "chain_selector": 16015286601757825753,
    }

    ARBITRUM_SEPOLIA = {
        "ccip_router": "0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165",
        "link": "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E",
        "usdc": "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d",
        "chain_selector": 3478487238524512106,
    }

    # Add Chainlink price feeds for different networks
    PRICE_FEEDS = {
        "sepolia": {
            "USDC_USD": "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E",
            "LINK_USD": "0xc59E3633BAAC79493d908e63626716e204A45EdF",
            "ETH_USD": "0x694AA1769357215DE4FAC081bf1f309aDC325306",
        },
        "arbitrum_sepolia": {
            "USDC_USD": "0x0153002d20B96532C639313c2d54c3dA09109309",
            "LINK_USD": "0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298",
            "ETH_USD": "0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165",
        }
    }


class DeploymentConfig:
    """Configuration for contract deployment"""

    # Gas settings
    GAS_LIMIT = 5000000
    GAS_PRICE_GWEI = 50

    # Compilation settings
    SOLC_VERSION = "0.8.20"
    OPTIMIZER_ENABLED = True
    OPTIMIZER_RUNS = 200

    # Contract paths (relative to project root)
    CONTRACT_DIR = "contracts"
    CONTRACTS = {
        "Factory": f"{CONTRACT_DIR}/Factory.sol",
        "Pair": f"{CONTRACT_DIR}/Pair_final_v3.sol",
        "LPToken": f"{CONTRACT_DIR}/LPToken.sol",
        "TransferUSDCBasic": f"{CONTRACT_DIR}/TransferUSDCBasic.sol",
        "MockUSDC": f"{CONTRACT_DIR}/mocks/MockUSDC.sol",
        "MockLINK": f"{CONTRACT_DIR}/mocks/MockLink.sol",
    }


def get_network_config(network: str) -> Dict:
    """
    Get configuration for a specific network

    Args:
        network: Network name ('ganache', 'sepolia', 'arbitrum_sepolia')

    Returns:
        Dictionary with network configuration
    """
    configs = {
        "ganache": {
            "rpc_url": NetworkConfig.GANACHE_RPC_URL,
            "chain_id": 1337,
            "is_testnet": True,
        },
        "sepolia": {
            "rpc_url": NetworkConfig.SEPOLIA_RPC_URL,
            "chain_id": 11155111,
            "is_testnet": True,
            "addresses": ContractAddresses.SEPOLIA,
            "price_feeds": ContractAddresses.PRICE_FEEDS["sepolia"],
        },
        "arbitrum_sepolia": {
            "rpc_url": NetworkConfig.ARBITRUM_SEPOLIA_RPC_URL,
            "chain_id": 421614,
            "is_testnet": True,
            "addresses": ContractAddresses.ARBITRUM_SEPOLIA,
            "price_feeds": ContractAddresses.PRICE_FEEDS["arbitrum_sepolia"],
        }
    }

    if network not in configs:
        raise ValueError(f"Unknown network: {network}. Available: {list(configs.keys())}")

    return configs[network]


# Example usage:
if __name__ == "__main__":
    print("Configuration loaded successfully!")
    print(f"Available networks: ganache, sepolia, arbitrum_sepolia")

    # Validate environment
    try:
        NetworkConfig.validate_private_key()
        print("✓ Private key configured")
    except ValueError as e:
        print(f"✗ {e}")
