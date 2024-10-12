#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}



# Function to install dependencies
install_dependency() {
    print_info "Updating and upgrading system packages..."
    sudo apt update && sudo apt upgrade -y && sudo apt install curl -y

    print_info "Installing Docker..."
    sudo apt install docker.io -y

    print_info "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose


    # Print Docker and Docker Compose versions to confirm installation
    print_info "Checking Docker version..."
    docker --version

    print_info "Checking Docker Compose version..."
    docker-compose --version

    
    # Call the uni_menu function to display the menu
    uni_menu
    
}




# Function to setup UniChain
uni_setup() {
    print_info "Cloning UniChain repository and entering the directory..."
    git clone https://github.com/Uniswap/unichain-node && cd unichain-node
    if [ $? -ne 0 ]; then
        print_error "Failed to clone or enter UniChain repository."
        exit 1
    fi

    print_info "Editing .env.sepolia file..."
    
    # Update the .env.sepolia file with new RPC URLs
    sed -i 's|^OP_NODE_L1_ETH_RPC=.*|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
    sed -i 's|^OP_NODE_L1_BEACON=.*|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia

    # Confirm changes were made
    if grep -q "OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com" .env.sepolia && \
       grep -q "OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com" .env.sepolia; then
        print_info ".env.sepolia updated successfully!"
    else
        print_error "Failed to update .env.sepolia file."
        exit 1
    fi


    # Call the uni_menu function to display the menu
    uni_menu


}



# Function to display menu and prompt user for input
uni_menu() {
    print_info "==============================="
    print_info "         UniChain Menu         "
    print_info "==============================="
    print_info ""
    print_info "1. Install-Dependency"
    print_info "2. Setup-UniChain"
    print_info ""
    print_info "==============================="
    
    read -p "Enter your choice (1 or 2): " user_choice

    case $user_choice in
        1)
            install_dependency
            ;;
        2)
            uni_setup
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 2."
            ;;
    esac
}

# Call the uni_menu function to display the menu
uni_menu


