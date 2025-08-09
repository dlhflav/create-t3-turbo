#!/bin/bash

# Script to setup .env file from .env.example and add missing variables from shell environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env.example exists
if [ ! -f ".env.example" ]; then
    log_error ".env.example file not found!"
    exit 1
fi

log_info "Checking .env file setup..."

# Create .env from .env.example if it doesn't exist
if [ ! -f ".env" ]; then
    log_info "Creating .env file from .env.example..."
    cp .env.example .env
    log_success "Created .env file"
else
    log_info ".env file already exists"
fi

# Function to extract variable names from .env.example (excluding comments and empty lines)
get_env_vars_from_example() {
    grep -E '^[A-Z_][A-Z0-9_]*=' .env.example | cut -d'=' -f1
}

# Function to check if a variable exists in .env file
var_exists_in_env() {
    local var_name="$1"
    grep -q "^${var_name}=" .env
}

# Function to remove existing variable from .env file
remove_var_from_env() {
    local var_name="$1"
    sed -i "/^${var_name}=/d" .env
}

# Function to get variable value from shell environment
get_shell_var_value() {
    local var_name="$1"
    eval "echo \$${var_name}"
}

# Get all variables from .env.example
env_vars=$(get_env_vars_from_example)

# Check each variable and add missing ones from shell environment
added_vars=0
for var in $env_vars; do
    if ! var_exists_in_env "$var"; then
        shell_value=$(get_shell_var_value "$var")
        if [ -n "$shell_value" ]; then
            log_info "Adding missing variable: $var"
            echo "${var}=${shell_value}" >> .env
            added_vars=$((added_vars + 1))
        else
            log_warning "Variable $var is missing from both .env and shell environment"
        fi
    fi
done

if [ $added_vars -gt 0 ]; then
    log_success "Added $added_vars variables from shell environment to .env"
else
    log_info "No missing variables found - .env file is up to date"
fi

# Add a newline before additional variables for better formatting
if [ -f ".env" ] && [ -s ".env" ]; then
    # Ensure the file ends with a newline
    if [ "$(tail -c1 .env | wc -l)" -eq 0 ]; then
        echo "" >> .env
    fi
    echo "" >> .env
fi

# Also check for additional common environment variables that might be useful
additional_vars=("VERCEL_TOKEN" "NGROK_TOKEN" "EXPO_TOKEN" "AUTH_DISCORD_SECRET")
for var in "${additional_vars[@]}"; do
    shell_value=$(get_shell_var_value "$var")
    if [ -n "$shell_value" ]; then
        if var_exists_in_env "$var"; then
            log_info "Updating existing variable: $var"
            remove_var_from_env "$var"
        else
            log_info "Adding additional variable: $var"
            added_vars=$((added_vars + 1))
        fi
        echo "${var}=${shell_value}" >> .env
    fi
done

log_success "Environment setup complete!"
log_info "Total variables added: $added_vars"

# Show summary of .env file
if [ -f ".env" ]; then
    log_info "Current .env file contents:"
    echo "----------------------------------------"
    cat .env
    echo "----------------------------------------"
fi