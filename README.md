## System Requirements

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 4 Cores                 |
| **RAM**      | 8 GB                    |
| **Disk**     | 60 GB                   |
| **Bandwidth**| 10 MBit/s               |




**Follow our TG : https://t.me/CryptoBureau01**

## Tool Installation Command

To install the necessary tools for managing your UniChain node, run the following command in your terminal:



```bash

cd $HOME && wget https://raw.githubusercontent.com/CryptoBureau01/UniChain/main/unichain.sh && chmod +x unichain.sh && ./unichain.sh
```




# UniChain Node Management Script

This Bash script provides a menu-driven interface to manage a UniChain node. Below are the key functions:

### Functions Overview

1. **`install_dependency()`**: 
   - Updates system packages and installs `curl`.
   - Checks for and installs Docker and Docker Compose if they are not already installed.
   - Displays installed versions of Docker and Docker Compose.

2. **`uni_setup()`**:
   - Clones the UniChain repository if it doesn't already exist.
   - Updates the `.env.sepolia` file with the appropriate RPC URLs.
   - Confirms the successful update of the configuration file.

3. **`uni_run()`**:
   - Navigates to the UniChain node directory and starts the node using Docker Compose.
   - Checks for the latest block after a brief pause.

4. **`priv_key()`**:
   - Fetches and displays the private key from the node.

5. **`restore_priv_key()`**:
   - Prompts the user to enter a new private key and saves it, replacing the existing key.

6. **`uni_stop()`**:
   - Stops the UniChain node and Docker containers.

7. **`uni_start()`**:
   - Starts the UniChain node and Docker containers.

8. **`op_node_logs()`**:
   - Fetches and displays logs for the UniChain Op-Node.

9. **`client_node_logs()`**:
   - Fetches and displays logs for the UniChain Client-Node.

10. **`uni_menu()`**:
    - Displays a menu for user interaction, allowing the selection of the above functions.
   





# Conclusion
This Auto Script for Node Management on the Unichain has been created by CryptoBuroMaster. It is a comprehensive solution designed to simplify and enhance the node management experience. By providing a clear and organized interface, it allows users to efficiently manage their nodes with ease. Whether you are a newcomer or an experienced user, this script empowers you to handle node operations seamlessly, ensuring that you can focus on what truly matters in your blockchain journey.


**Join our TG : https://t.me/CryptoBuroOfficial**
