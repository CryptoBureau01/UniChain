#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}


setup_contract_environment() {
    CONTRACT_DIR="/root/unichain-node/contract"

    # Create the contract directory if it doesn't exist
    if [ ! -d "$CONTRACT_DIR" ]; then
        print_info "Folder $CONTRACT_DIR does not exist. Creating the folder..."
        mkdir -p "$CONTRACT_DIR"
    else
        print_info "Folder $CONTRACT_DIR already exists."
    fi
    
    # Get private key from the nodekey file
    nodekey_file="/root/unichain-node/geth-data/geth/nodekey"
    
    if [ -f "$nodekey_file" ]; then
        PRIVATE_KEY=$(cat "$nodekey_file")
        print_info "Private key retrieved from $nodekey_file."
    else
        print_error "Private key file does not exist: $nodekey_file"
        exit 1
    fi

    # Get user input for token name and token symbol
    read -p "Enter the token name (e.g. CryptoBuro): " TOKEN_NAME
    read -p "Enter the token symbol (e.g., CB ): " TOKEN_SYMBOL
    
    # Save details to .env.contract file using echo
    print_info "Saving details to $CONTRACT_DIR/.env.contract..."
    echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" > "$CONTRACT_DIR/.env.contract"
    echo "TOKEN_NAME=\"$TOKEN_NAME\"" >> "$CONTRACT_DIR/.env.contract"
    echo "TOKEN_SYMBOL=\"$TOKEN_SYMBOL\"" >> "$CONTRACT_DIR/.env.contract"

    # Source the .env.contract file to load variables
    source "$CONTRACT_DIR/.env.contract"
    
    print_info "Environment setup complete. Token details saved in $CONTRACT_DIR/.env.contract."
}





# Function to set up the project, Git repo, and dependencies
setup_project() {
    CONTRACT_DIR="/root/unichain-node/contract"
    cd "$CONTRACT_DIR" || exit

    # Initialize Git if not already initialized
    if [ ! -d ".git" ]; then
        print_info "Initializing Git repository..." 
        git init
    fi

    # Install Foundry if not installed
    if ! command -v forge &> /dev/null; then
        print_info "Foundry is not installed. Installing now..."
        source <(wget -O - https://raw.githubusercontent.com/CryptoBuroMaster/UniChain/refs/heads/main/contract/contract-setup.sh)
    fi

    # Install OpenZeppelin Contracts
    if [ ! -d "$CONTRACT_DIR/lib/openzeppelin-contracts" ]; then
        print_info "Installing OpenZeppelin Contracts..." 
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$CONTRACT_DIR/lib/openzeppelin-contracts"
    else
        print_info "OpenZeppelin Contracts already installed."
    fi

    # Create foundry.toml if it doesn't exist
    if [ ! -f "$CONTRACT_DIR/foundry.toml" ]; then
       print_info "Creating foundry.toml and adding Unichain RPC..."
       echo "[profile.default]" > "$CONTRACT_DIR/foundry.toml"
       echo "src = \"src\"" >> "$CONTRACT_DIR/foundry.toml"
       echo "out = \"out\"" >> "$CONTRACT_DIR/foundry.toml"
       echo "libs = [\"lib\"]" >> "$CONTRACT_DIR/foundry.toml"
       echo "" >> "$CONTRACT_DIR/foundry.toml"
       echo "[rpc_endpoints]" >> "$CONTRACT_DIR/foundry.toml"
       echo "unichain = \"https://sepolia.unichain.org\"" >> "$CONTRACT_DIR/foundry.toml"
    else
       print_info "foundry.toml already exists."
    fi
}



# Function to create, compile, and deploy the ERC-20 contract
create_and_deploy_contract() {
    CONTRACT_DIR="/root/unichain-node/contract"
    cd "$CONTRACT_DIR" || exit

    # Source the environment variables
    source "$CONTRACT_DIR/.env.contract"

    # Create the ERC-20 token contract using OpenZeppelin
    print_info "Creating ERC-20 token contract using OpenZeppelin..." 
    mkdir -p "$CONTRACT_DIR/src"

    # Create the contract file and write the contents
    echo "// SPDX-License-Identifier: MIT" > "$CONTRACT_DIR/src/Buro.sol"
    echo "pragma solidity ^0.8.20;" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "import \"@openzeppelin/contracts/token/ERC20/ERC20.sol\";" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "contract Buro is ERC20 {" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "    constructor() ERC20(\"$TOKEN_NAME\", \"$TOKEN_SYMBOL\") {" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "        _mint(msg.sender, 100000 * (10 ** decimals()));" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "    }" >> "$CONTRACT_DIR/src/Buro.sol"
    echo "}" >> "$CONTRACT_DIR/src/Buro.sol"

    
    # Compile the contract
    print_info "Compiling the contract..." 
    forge build

    if [[ $? -ne 0 ]]; then
        print_error "Contract compilation failed."
        exit 1
    fi

    # Deploy the contract
    print_info "Deploying the contract to Unichain..." 
    DEPLOY_OUTPUT=$(forge create "$CONTRACT_DIR/src/Buro.sol:Buro" \
        --rpc-url unichain \
        --private-key "$PRIVATE_KEY")

    if [[ $? -ne 0 ]]; then
        print_error "Deployment failed."
        exit 1
    fi

    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
    print_info "Token deployed successfully at address: https://sepolia.uniscan.xyz/address/$CONTRACT_ADDRESS"
}




# Function to clean up unnecessary files
cleanup() {
    CONTRACT_DIR="/root/unichain-node/contract"

    # Remove OpenZeppelin Contracts directory
    if [ -d "$CONTRACT_DIR/lib/openzeppelin-contracts" ]; then
        print_info "Removing OpenZeppelin Contracts..."
        rm -rf "$CONTRACT_DIR/lib/openzeppelin-contracts"
    else
        print_info "OpenZeppelin Contracts directory does not exist."
    fi

    # Remove contract-setup.sh if it exists
    if [ -f "$CONTRACT_DIR/contract-setup.sh" ]; then
        print_info "Removing contract-setup.sh..."
        rm -f "$CONTRACT_DIR/contract-setup.sh"
    else
        print_info "contract-setup.sh does not exist."
    fi
}

# Execute the functions
setup_contract_environment
setup_project
create_and_deploy_contract
cleanup
