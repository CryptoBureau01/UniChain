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
    print_info "Updating and upgrading system packages, and installing curl..."
    sudo apt update && sudo apt upgrade -y && sudo apt install curl -y

    # Check if Docker is already installed
    if ! command -v docker &> /dev/null; then
        print_info "Docker is not installed. Installing Docker..."
        sudo apt install docker.io -y

        # Check for installation errors
        if [ $? -ne 0 ]; then
            print_error "Failed to install Docker. Please check your system for issues."
            exit 1
        fi
    else
        print_info "Docker is already installed."
    fi

    # Check if Docker Compose is already installed
    if ! command -v docker-compose &> /dev/null; then
        print_info "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        # Check for installation errors
        if [ $? -ne 0 ]; then
            print_error "Failed to install Docker Compose. Please check your system for issues."
            exit 1
        fi
    else
        print_info "Docker Compose is already installed."
    fi

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




# Function to run UniChain and check the node
uni_run() {
    print_info "Setting port 8546 for UniChain..."
    # Start UniChain on port 8546 using Docker Compose
    docker-compose up -d

    # Wait for a few seconds to ensure the node is running
    sleep 5

    # Check latest block
    print_info "Checking latest block..."
    response=$(curl -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8546)

    if [[ $response == *"\"error\":"* ]]; then
        print_error "Failed to retrieve the latest block. Check if the UniChain node is running correctly."
    else
        print_info "Successfully retrieved the latest block information."
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
    print_info "3. Uni-Node-Run"
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
        3) 
            uni_run
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 2."
            ;;
    esac
}

# Call the uni_menu function to display the menu
uni_menu


