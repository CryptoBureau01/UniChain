#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

check_foundry_installed() {
    if command -v forge >/dev/null 2>&1; then
        print_info "Foundry is already installed."
        return 0
    else
        return 1
    fi
}

install_foundry() {
    print_info "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash

    export PATH="$HOME/.foundry/bin:$PATH"

    print_info "Installing essential tools: cast, anvil..."
    foundryup
}

add_foundry_to_path() {
    if grep -q "foundry/bin" "$HOME/.bashrc" || grep -q "foundry/bin" "$HOME/.zshrc"; then
        print_info "Foundry is already added to PATH."
    else
        print_info "Adding Foundry to PATH..."

        if [ -f "$HOME/.bashrc" ]; then
            echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.zshrc"
        else
            echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.profile"
        fi
    fi
}

validate_path() {
    print_info "Validating PATH setup..."
    if ! command -v forge >/dev/null 2>&1 || ! command -v cast >/dev/null 2>&1 || ! command -v anvil >/dev/null 2>&1; then
        print_error "PATH not properly set in the current session."
        return 1
    else
        print_info "Foundry tools are working fine in the current session."
    fi

    future_shell_test=$(bash -c "command -v forge && command -v cast && command -v anvil")
    if [ -z "$future_shell_test" ]; then
        print_error "PATH not properly set for future shell sessions."
        return 1
    else
        print_info "Foundry tools are working fine in future shell sessions."
    fi

    return 0
}

print_info "Checking if Foundry is already installed..."
if check_foundry_installed; then
    print_info "Foundry is already installed. Validating the PATH setup..."
    validate_path
else
    install_foundry
    add_foundry_to_path
    validate_path
fi

print_info "Foundry installation and PATH setup complete."
