#!/bin/bash

curl -s https://raw.githubusercontent.com/CryptoBureau01/logo/main/logo.sh | bash
sleep 5

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
    print_info "<=========== Install Dependency ==============>"
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

    # Check if geth is installed, if not, install it
    if ! command -v geth &> /dev/null
      then
         print_info "Geth is not installed. Installing now..."
    
    # Geth install
    sudo apt install ethereum -y
    
    print_info "Geth installation complete."
    else
        print_info "Geth is already installed."
    fi

    # Print Docker and Docker Compose versions to confirm installation
    print_info "Checking Docker version..."
    docker --version

     print_info "Checking Docker Compose version..."
     docker-compose --version

    # Print Geth version
    print_info "Checking Geth version..."
    geth version


    # Call the uni_menu function to display the menu
    uni_menu
}

    
    
    


# Function to setup UniChain
uni_setup() {
    print_info "<=========== UniChain Setup ==============>"
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
    
    print_info "Allowing necessary ports in the firewall..."

    # Allow port 8548
    sudo ufw allow 8548/tcp
    sudo ufw allow 8548/udp
    sudo ufw allow 8549/tcp
    sudo ufw allow 8549/udp
    sudo ufw allow 8546/tcp
    sudo ufw allow 8546/udp
    sudo ufw allow 8552/tcp
    sudo ufw allow 8551/tcp
    
    # Allow port 30304
    sudo ufw allow 30304/tcp
    sudo ufw allow 30304/udp

    # Update docker-compose.yml to change port 30303 to 30304
    sed -i 's|30303:30303|30304:30303|' docker-compose.yml

    # Update docker-compose.yml to change port 8545 to 8548
    sed -i 's|8545:8545|8548:8545|' docker-compose.yml

    # Update docker-compose.yml to change port 8546 to 8549
    sed -i 's|8546:8546|8549:8546|' docker-compose.yml

    # Update docker-compose.yml to change port 8551 to 8552
    sed -i 's|8551:8551|8552:8551|' docker-compose.yml
    
    # Check the status to confirm the rules are added
    if sudo ufw status | grep -q "8548"; then
        print_info "Port 8548 allowed in the firewall."
    else
        print_error "Failed to allow port 8548."
        exit 1
    fi

    if sudo ufw status | grep -q "8549"; then
        print_info "Port 8549 allowed in the firewall."
    else
        print_error "Failed to allow port 8549."
        exit 1
    fi

    if sudo ufw status | grep -q "30304"; then
        print_info "Port 30304 allowed in the firewall."
    else
        print_error "Failed to allow port 30304."
        exit 1
    fi

    

    # Call the uni_menu fuction to display the menu
    uni_menu

}




# Function to run UniChain and check the node
uni_run() {
    print_info "<=========== UniChain Node Run ==============>"
    print_info "Navigating to UniChain node directory..."
    
    # Navigate to the unichain-node directory
    cd /root/unichain-node || {
        print_error "Failed to navigate to /root/unichain-node. Check if the directory exists."
        return
    }

    print_info "Setting port 8546 for UniChain..."
    
    # Start UniChain on port 8548 using Docker Compose
    docker-compose up -d || {
        print_error "Failed to start UniChain. Check Docker configuration."
        return
    }

    # Wait for a few seconds to ensure the node is running
    sleep 5

    # Check the latest block
    print_info "Checking the latest block..."
    response=$(curl -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8548)

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
    print_info "<=========== Check Private key ==============>"
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



# Function to restore private key
restore_priv_key() {
    print_info "<=========== Restore Private Key ==============>"
    print_info "Please enter your private key:"

    # Read user input for the private key
    read -r user_private_key

    # Define the path to the nodekey file
    nodekey_file="/root/unichain-node/geth-data/geth/nodekey"

    # Check if the nodekey file exists
    if [ -f "$nodekey_file" ]; then
        # Delete the existing nodekey file
        rm -f "$nodekey_file"
        print_info "Old node key file deleted."
    fi

    # Save the new private key to the nodekey file
    echo "$user_private_key" > "$nodekey_file"
    print_info "Private Key restored successfully!"

    # Optionally return to the menu after restoring the key
    uni_menu
}




# Function to stop UniChain
uni_stop() {

    print_info "<=========== UniChain Node Stop ==============>"
    print_info "Stopping the UniChain node..."
    
    # Navigate to the UniChain node directory
    cd /root/unichain-node || { print_error "Failed to navigate to UniChain directory."; return 1; }

    # Stop the Docker containers
    docker-compose down
    
    if [ $? -eq 0 ]; then
        print_info "UniChain node stopped successfully."
    else
        print_error "Failed to stop the UniChain node."
    fi

    # Optionally, return to the menu after stopping the node
    uni_menu
}





# Function to start UniChain
uni_start() {
    print_info "<=========== UniChain Node Start ==============>"
    print_info "Starting the UniChain node..."

    # Navigate to the UniChain node directory
    cd /root/unichain-node || { print_error "Failed to navigate to UniChain directory."; return 1; }

    # Start the Docker containers
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        print_info "UniChain node started successfully."
    else
        print_error "Failed to start the UniChain node."
    fi

    # Optionally, return to the menu after starting the node
    uni_menu
}



#Cintract Deploy Function 
contract() {
    print_info "<================= Contract Deploy ================>"
    
    rm -f /root/contract.sh
    rm -f /root/contract.sh.1

    # Download the contract setup script
    print_info "Downloading contract setup script..."
    curl -L -o /root/contract.sh https://raw.githubusercontent.com/CryptoBureau01/UniChain/main/contract/contract.sh

    # Check if the download was successful
    if [[ $? -ne 0 ]]; then
        print_info "Failed to download contract.sh"
        return 1  # Exit the function with an error
    fi

    chmod +x /root/contract.sh && /root/contract.sh

    print_info "Contract Deploy successfully!"

    # Optionally, return to the menu after showing the Contract deploy 
    uni_menu
}




# Function to display Op-Node logs
op_node_logs() {
    print_info "<=========== UniChain Op Node Logs ==============>"
    print_info "Fetching logs for the UniChain-Op-Node..."
    
    # Fetch the Docker logs for the Op-Node container
    docker logs unichain-node-op-node-1

    if [ $? -eq 0 ]; then
        print_info "Displayed Op-Node logs successfully."
    else
        print_error "Failed to fetch Op-Node logs. Make sure the container is running."
    fi

    # Optionally, return to the menu after showing the logs
    uni_menu
}




# Function to display Client-Node logs
client_node_logs() {
    print_info "<=========== UniChain Client Node Logs ==============>"
    print_info "Fetching logs for the UniChain Client-Node..."

    # Fetch the Docker logs for the Client-Node container
    docker logs unichain-node-execution-client-1

    if [ $? -eq 0 ]; then
        print_info "Displayed Client-Node logs successfully."
    else
        print_error "Failed to fetch Client-Node logs. Make sure the container is running."
    fi

    # Optionally, return to the menu after showing the logs
    uni_menu
}




# Function to display menu and prompt user for input
uni_menu() {
    print_info "==============================="
    print_info "    UniChain Node Tool Menu    "
    print_info "==============================="
    print_info ""
    print_info "1. Install-Dependency"
    print_info "2. Setup-UniChain"
    print_info "3. UniChain-Node-Run"
    print_info "4. Check-Private-Key"
    print_info "5. Private-Key Restore"
    print_info "6. Stop-Node"
    print_info "7. Start-Node"
    print_info "8. Contract-Deploy"
    print_info "9. Op-Node-Logs"
    print_info "10. Client-Node-Logs"
    print_info "11. Exit"
    print_info ""
    print_info "==============================="
    print_info " Created By : CryptoBuroMaster "
    print_info "==============================="
    print_info ""
    
    read -p "Enter your choice (1 or 11): " user_choice

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
        5)  
            restore_priv_key
            ;;
        6)
            uni_stop
            ;;
        7) 
            uni_start
            ;;
        8) 
            contract
            ;;
        9) 
            op_node_logs
            ;;
        10)
            client_node_logs
            ;;
        11)
            exit 0  # Exit the script after breaking the loop
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 11 : "
            ;;
    esac
}

# Call the uni_menu function to display the menu
uni_menu


