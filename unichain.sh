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






update_docker_compose_ports() {
    # Define the path to your docker-compose.yml file
    local compose_file="/root/unichain-node/docker-compose.yml"
    
    # Check if the file exists
    if [[ ! -f $compose_file ]]; then
        print_error "docker-compose.yml file not found at $compose_file"
        exit 1
    fi

    # Backup the original file
    cp "$compose_file" "${compose_file}.bak"

    # Use sed to update the ports section
    sed -i.bak -E '
    /^ports:/,/^[^ ]/{ 
        s/30304:30304\/udp/30304:30304\/udp/
        s/30304:30304\/tcp/30304:30304\/tcp/
        s/8545:8545\/tcp/8545:8545\/tcp/
        s/8546:8546\/tcp/8546:8546\/tcp/
    }' "$compose_file"

    print_info "Updated ports in $compose_file"

    # Call the uni_menu fuction to display the menu
    uni_menu
}



port_response() {
    print_info "Checking response from http://localhost:8545..."
    
    for i in {1..5}; do  # Loop to check response 5 times
        response=$(curl -s http://localhost:8545)
        
        if [[ -n "$response" ]]; then
            print_info "Received response from port 8545."
            return 0  # Break out of the function if response is received
        else
            print_error "No response from port 8545. Attempting to allow the port again..."
            
            # Allow the port again
            sudo ufw allow 8545
            
            # Check if the port was allowed successfully
            if sudo ufw status | grep -q "8545"; then
                print_info "Port 8545 has been allowed in the firewall."
            else
                print_error "Failed to allow port 8545."
                exit 1
            fi

            # Wait for a few seconds before retrying
            sleep 2  # Wait for 2 seconds before next check
        fi
    done
    
    print_error "Failed to receive response from port 8545 after 5 attempts."
    exit 1
}


port() {
    print_info "Allowing necessary ports in the firewall..."
    
    # Function to attempt allowing ports
    attempt_port_allow() {
        sudo ufw allow 30304/tcp
        sudo ufw allow 30304/udp
        sudo ufw allow 8545/tcp
        sudo ufw allow 8545/udp
        sudo ufw allow 8546/tcp
        sudo ufw allow 8546/udp
    }
    
    # Loop to try allowing ports up to 5 times
    for i in {1..5}; do
        attempt_port_allow

        # Checking if both ports are allowed in the firewall
        if sudo ufw status | grep -q "30304" && sudo ufw status | grep -q "8545"; then
            print_info "Ports 30304 and 8545 (TCP/UDP) successfully allowed in the firewall."
            break
        else
            print_error "Attempt $i: Failed to allow necessary ports in the firewall."
        fi

        # If this is the 5th attempt and it still failed, exit with error
        if [ "$i" -eq 5 ]; then
            print_error "Exceeded maximum attempts. Ports were not allowed."
            exit 1
        fi

        # Wait for a second before trying again
        sleep 1
    done

    # Update port in Docker Services file
    update_docker_compose_ports
}




block() {
    # Check the latest block
    print_info "Checking the latest block..."
    
    # Sending request to check the latest block
    response=$(curl -s -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545)
    
    # Checking if there's an error in the response
    if [[ $response == *"\"error\":"* ]]; then
        print_error "Failed to retrieve the latest block. Check if the node is running correctly."
        port_response
        
        # Check if the node process is running on the system
        if pgrep -f "geth" > /dev/null; then
            print_info "The node process is running, but there seems to be an issue with block retrieval."
        else
            print_error "Node process is not running. Please start the node."
            exit 1
        fi
        
    # Checking if the block number is missing or null
    elif [[ $response == *"null"* ]]; then
        print_error "No block information available. The node might be syncing or there could be a network issue."
        docker-compose restart

       sleep 5
    else
        print_info "Successfully retrieved the latest block information."
        echo "$response" | jq .result.number  # Prints the block number
    fi

    # Call the uni_menu function to display the menu
    uni_menu
}



# Function to install dependencies
install_dependency() {
    print_info "<=========== Install Dependency ==============>"
    print_info "Updating and upgrading system packages, and installing curl..."
    sudo apt update && sudo apt upgrade -y && sudo apt install git wget curl -y 

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

    # Port allow 
    port
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
 
    # Start UniChain on port 8545 using Docker Compose
    docker-compose up -d || {
        print_error "Failed to start UniChain. Check Docker configuration."
        return
    }

    # Wait for a few seconds to ensure the node is running
    sleep 5

    # block number test
    block
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


