#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}



contract_dir() {
CONTRACT_DIR="/root/unichain-node/contract"
    
    # Check if the folder exists
    if [ -d "$CONTRACT_DIR" ]; then
        print_info "Folder $CONTRACT_DIR already exists."
    else
        print_info "Folder $CONTRACT_DIR does not exist. Creating the folder..."
        mkdir -p "$CONTRACT_DIR"
    fi
}



# Function to create or use existing contract folder and save .env.contract file
setup_contract_environment() {
    CONTRACT_DIR="/root/unichain-node/contract"
    
    # Check if the folder exists
    if [ -d "$CONTRACT_DIR" ]; then
        print_info "Folder $CONTRACT_DIR already exists."
    else
        print_info "Folder $CONTRACT_DIR does not exist. Creating the folder..."
        mkdir -p "$CONTRACT_DIR"
    fi
    
    # Get user input for private key, token name, and token symbol
    read -p "Enter your Private Key: " PRIVATE_KEY
    read -p "Enter the token name (e.g., Token): " TOKEN_NAME
    read -p "Enter the token symbol (e.g., ETH): " TOKEN_SYMBOL
    
    # Save details to .env.contract file
    print_info "Saving details to $CONTRACT_DIR/.env.contract..."
    cat <<EOL > "$CONTRACT_DIR/.env.contract"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
EOL

    # Source the .env.contract file to load variables
    source "$CONTRACT_DIR/.env.contract"
    
    print_info "Environment setup complete. Token details saved in $CONTRACT_DIR/.env.contract."
}

# Call the function to set up the contract environment
setup_contract_environment




# Function to set up the project, Git repo, and dependencies
setup_project() {
    CONTRACT_DIR="/root/unichain-node/contract"
    mkdir -p "$CONTRACT_DIR"
    cd "$CONTRACT_DIR" || exit

    CONTRACT_NAME="Buro"

    # Initialize Git if not already initialized
    if [ ! -d ".git" ]; then
        show "Initializing Git repository..." "progress"
        git init
    fi

    # Install Foundry if not installed
    if ! command -v forge &> /dev/null; then
        show "Foundry is not installed. Installing now..." "progress"
        source <(wget -O - https://github.com/CryptoBuroMaster/UniChain/blob/main/contract/contract-setup.sh)
    fi

    # Install OpenZeppelin Contracts
    if [ ! -d "$CONTRACT_DIR/lib/openzeppelin-contracts" ]; then
        show "Installing OpenZeppelin Contracts..." "progress"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$CONTRACT_DIR/lib/openzeppelin-contracts"
    else
        show "OpenZeppelin Contracts already installed."
    fi

    # Create foundry.toml if it doesn't exist
    if [ ! -f "$CONTRACT_DIR/foundry.toml" ]; then
        show "Creating foundry.toml and adding Unichain RPC..." "progress"
        cat <<EOL > "$CONTRACT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
unichain = "https://sepolia.unichain.org"
EOL
    else
        show "foundry.toml already exists."
    fi
}






# Function to create, compile, and deploy the ERC-20 contract
create_and_deploy_contract() {
    CONTRACT_DIR="/root/unichain-node/contract"
    cd "$CONTRACT_DIR" || exit

    # Source the environment variables
    source "$CONTRACT_DIR/.env.contract"

    show "Creating ERC-20 token contract using OpenZeppelin..." "progress"
    mkdir -p "$CONTRACT_DIR/src"
    cat <<EOL > "$CONTRACT_DIR/src/$CONTRACT_NAME.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract $CONTRACT_NAME is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 100000 * (10 ** decimals()));
    }
}
EOL

    # Compile the contract
    show "Compiling the contract..." "progress"
    forge build

    if [[ $? -ne 0 ]]; then
        show "Contract compilation failed." "error"
        exit 1
    fi

    # Deploy the contract
    show "Deploying the contract to Unichain..." "progress"
    DEPLOY_OUTPUT=$(forge create "$CONTRACT_DIR/src/$CONTRACT_NAME.sol:$CONTRACT_NAME" \
        --rpc-url unichain \
        --private-key "$PRIVATE_KEY")

    if [[ $? -ne 0 ]]; then
        show "Deployment failed." "error"
        exit 1
    fi

    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
    show "Token deployed successfully at address: https://sepolia.uniscan.xyz/address/$CONTRACT_ADDRESS"
}

# Execute the functions
setup_project
create_and_deploy_contract




