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
    # Check if the 'unichain-node' directory exists
    if [ -d "unichain-node" ]; then
        print_info "UniChain node folder already exists. Navigating to the directory..."
        cd unichain-node
    else
        print_info "Cloning UniChain repository and entering the directory..."
        git clone https://github.com/Uniswap/unichain-node && cd unichain-node
        if [ $? -ne 0 ]; then
            print_error "Failed to clone or enter UniChain repository."
            exit 1
        fi
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

    print_info "Updating Docker Compose ports to avoid conflict on port 30303..."
    
    # Update docker-compose.yml to change port 30303 to 30304
    sed -i 's|30303:30303|30304:30303|' docker-compose.yml

    # Confirm changes were made
    if grep -q "30304:30303" docker-compose.yml; then
        print_info "Docker Compose ports updated successfully!"
    else
        print_error "Failed to update Docker Compose ports."
        exit 1
    fi


    # Call the uni_menu function to display the menu
    uni_menu

}




# Function to run UniChain and check the node
uni_run() {
    print_info "Navigating to UniChain node directory..."
    
    # Navigate to the unichain-node directory
    cd /root/unichain-node || {
        print_error "Failed to navigate to /root/unichain-node. Check if the directory exists."
        return
    }

    print_info "Setting port 8546 for UniChain..."
    
    # Start UniChain on port 8546 using Docker Compose
    docker-compose up -d || {
        print_error "Failed to start UniChain. Check Docker configuration."
        return
    }

    # Wait for a few seconds to ensure the node is running
    sleep 5

    # Check the latest block
    print_info "Checking the latest block..."
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




# Function to display the private key
priv_key() {
    print_info "Fetching the private key from the node..."

    # Define the path to the nodekey file
    nodekey_file="/root/unichain-node/geth-data/geth/nodekey"

    # Check if the nodekey file exists
    if [ -f "$nodekey_file" ]; then
        # Read and display the private key
        private_key=$(cat "$nodekey_file")
        print_info "Private Key: $private_key"
    else
        print_error "Node key file not found. Please ensure the file exists at $nodekey_file."
    fi

    # Optionally return to the menu after displaying the key
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
    print_info "4. Check-Private-Key"
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
        4) 
            priv_key
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 4 : "
            ;;
    esac
}

# Call the uni_menu function to display the menu
uni_menu


