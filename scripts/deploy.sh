#!/bin/bash

# T3 Turbo Deployment Script
# This script handles both web and mobile deployments with ngrok tunneling

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}🔧 $1${NC}"; }
log_deploy() { echo -e "${PURPLE}🚀 $1${NC}"; }

# Clean live output logs
clean_logs() {
    local app_type=${1:-"all"}
    log_step "Cleaning live output logs for $app_type..."
    
    # Always clean general logs
    rm -f live_output.log live_console.log tunnel_live.log console_output.log tunnel_output.log current_console.log deployment-*.log
    
    # Clean app-specific logs based on app type
    case $app_type in
        "web"|"next")
            rm -f web_output.log
            log_success "Web logs cleaned"
            ;;
        "mobile"|"expo")
            rm -f mobile_output.log
            log_success "Mobile logs cleaned"
            ;;
        "all")
            rm -f web_output.log mobile_output.log
            log_success "All logs cleaned"
            ;;
        *)
            log_warning "Unknown app type for log cleaning: $app_type"
            ;;
    esac
}

# Install environment file and configure setup
install_env_file() {
    local app_type=$1
    log_step "Installing environment file for $app_type..."
    
    # Setup environment variables
    log_step "Setting up environment variables for $app_type..."
    setup_environment_variables
    log_success "Environment variables configured for $app_type"
    
    # Configure ngrok tunnels
    log_step "Configuring ngrok tunnels for $app_type..."
    install_ngrok
    log_success "Ngrok tunnels configured for $app_type"
    
    log_success "Environment file installation complete for $app_type"
    return 0
}

# Install JavaScript packages for specific app
install_packages() {
    local app_type=$1
    log_step "Installing JavaScript packages for $app_type..."
    
    case $app_type in
        "web"|"next")
            log_info "Installing Next.js dependencies..."
            cd apps/nextjs
            pnpm install 2>&1 | tee ../../web_output.log
            if [ $? -eq 0 ]; then
                log_success "Next.js dependencies installed"
            else
                log_error "Failed to install Next.js dependencies"
                cd ../..
                return 1
            fi
            cd ../..
            ;;
        "mobile"|"expo")
            log_info "Installing Expo dependencies..."
            cd apps/expo
            pnpm install 2>&1 | tee ../../mobile_output.log
            if [ $? -eq 0 ]; then
                log_success "Expo dependencies installed"
            else
                log_error "Failed to install Expo dependencies"
                cd ../..
                return 1
            fi
            cd ../..
            ;;
        *)
            log_error "Unknown app type: $app_type"
            return 1
            ;;
    esac
    
    log_success "$app_type dependencies are ready"
    return 0
}

# Load environment variables safely
load_env() {
    if [ -f .env ]; then
        log_info "Loading environment variables from .env"
        while IFS= read -r line; do
            [[ $line =~ ^[[:space:]]*# ]] && continue
            [[ -z $line ]] && continue
            if [[ $line =~ ^(VERCEL_TOKEN|NGROK_TOKEN|EXPO_TOKEN)= ]]; then
                export "$line"
            fi
        done < .env
    else
        log_warning ".env file not found, using environment variables"
    fi
}

# Setup environment variables from .env.example and shell environment
setup_environment_variables() {
    # Check if .env.example exists
    if [ ! -f ".env.example" ]; then
        log_warning ".env.example file not found, skipping environment setup"
        return 0
    fi

    # Create .env from .env.example if it doesn't exist
    if [ ! -f ".env" ]; then
        log_info "Creating .env file from .env.example..."
        cp .env.example .env
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
            fi
        fi
    done

    if [ $added_vars -gt 0 ]; then
        log_info "Added/updated $added_vars variables from shell environment"
    fi
}

# Install and configure ngrok
install_ngrok() {
    log_step "Installing and configuring ngrok..."
    
    # Function to get variable value from shell environment
    get_shell_var_value() {
        local var_name="$1"
        eval "echo \$${var_name}"
    }
    
    # Check if ngrok is installed
    if ! command -v ngrok &> /dev/null; then
        log_info "Ngrok not found, installing..."
        
        # Add ngrok repository and install
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
        sudo apt update && sudo apt install -y ngrok
        
        if [ $? -eq 0 ]; then
            log_success "Ngrok installed successfully"
        else
            log_error "Failed to install ngrok"
            return 1
        fi
    else
        log_info "Ngrok already installed: $(ngrok version)"
    fi
    
    # Get NGROK_TOKEN from environment
    local ngrok_token=$(get_shell_var_value "NGROK_TOKEN")
    if [ -z "$ngrok_token" ]; then
        log_warning "NGROK_TOKEN not found in environment, skipping ngrok configuration"
        return 0
    fi
    
    # Create ngrok config directory
    mkdir -p ~/.config/ngrok
    
    # Check if config file exists and needs updating
    local config_file=~/.config/ngrok/ngrok.yml
    local config_needs_update=false
    
    if [ ! -f "$config_file" ]; then
        config_needs_update=true
        log_info "Ngrok config file not found, creating new one"
    else
        # Check if token is different
        local current_token=$(grep -o 'authtoken: [^[:space:]]*' "$config_file" | cut -d' ' -f2)
        if [ "$current_token" != "$ngrok_token" ]; then
            config_needs_update=true
            log_info "Ngrok token changed, updating config"
        fi
        
        # Check if endpoints need updating
        if ! grep -q "name: web" "$config_file" || ! grep -q "name: mobile" "$config_file"; then
            config_needs_update=true
            log_info "Ngrok endpoints missing, updating config"
        fi
    fi
    
    if [ "$config_needs_update" = true ]; then
        # Create/update ngrok configuration file
        cat > "$config_file" << EOF
version: 3
agent:
  authtoken: ${ngrok_token}
endpoints:
  - name: web
    url: gopher-assuring-seriously.ngrok-free.app
    upstream:
      url: http://localhost:3000
  - name: mobile
    url: gopher-assuring-seriously.ngrok-free.app
    upstream:
      url: http://localhost:8081
EOF
        
        log_success "Ngrok configuration updated at $config_file"
        log_info "Web tunnel: gopher-assuring-seriously.ngrok-free.app -> http://localhost:3000"
        log_info "Mobile tunnel: gopher-assuring-seriously.ngrok-free.app -> http://localhost:8081"
    else
        log_info "Ngrok configuration is up to date"
    fi
    
    return 0
}

# Configure ngrok with tunnels (legacy function, now calls install_ngrok)
configure_ngrok() {
    install_ngrok
}

# Check if token is set
check_token() {
    local token_name=$1
    local token_value=$2
    
    if [ -z "$token_value" ] || [ "$token_value" = "your-$token_name-here" ]; then
        log_error "$token_name not set"
        return 1
    fi
    return 0
}

# Start ngrok tunnel
start_ngrok() {
    local port=$1
    log_step "Starting ngrok tunnel on port $port..."
    
    if ! check_token "NGROK_TOKEN" "$NGROK_TOKEN"; then
        log_warning "Skipping ngrok - NGROK_TOKEN not configured"
        return 1
    fi
    
    # Configure ngrok if needed
    if [ ! -f ~/.config/ngrok/ngrok.yml ]; then
        log_step "Configuring ngrok..."
        ngrok config add-authtoken "$NGROK_TOKEN"
    fi
    
    # Start ngrok tunnel with live output
    ngrok http $port 2>&1 | tee web_output.log &
    NGROK_PID=$!
    sleep 5
    
    # Get tunnel URL
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])" 2>/dev/null || echo "Unknown")
        log_success "Ngrok tunnel: $TUNNEL_URL"
        log_info "Monitor: http://localhost:4040"
        return 0
    else
        log_error "Failed to start ngrok tunnel"
        return 1
    fi
}

# Start web development server
start_web_dev() {
    log_step "Starting web development server..."
    
    if [ ! -d "node_modules" ]; then
        log_step "Installing dependencies..."
        pnpm install
    fi
    
    log_success "Starting web server on http://localhost:3000"
    pnpm dev:next 2>&1 | tee web_output.log &
    WEB_PID=$!
    sleep 10
    
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Web server is running"
        return 0
    else
        log_error "Failed to start web server"
        return 1
    fi
}

# Start mobile development server
start_mobile_dev() {
    log_step "Starting mobile development server..."
    
    cd apps/expo
    log_success "Starting Expo server on http://localhost:8081"
    npx expo start --lan 2>&1 | tee ../../mobile_output.log &
    MOBILE_PID=$!
    cd ../..
    sleep 10
    
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        log_success "Mobile server is running"
        return 0
    else
        log_error "Failed to start mobile server"
        return 1
    fi
}

# Start mobile development server with tunnel
start_mobile_tunnel() {
    log_step "Starting mobile development server with tunnel..."
    
    # Check if NGROK_TOKEN is available for Expo tunnel
    if ! check_token "NGROK_TOKEN" "$NGROK_TOKEN"; then
        log_warning "NGROK_TOKEN not configured - Expo tunnel requires ngrok authentication"
        log_info "Using LAN mode instead. For tunnel access, set NGROK_TOKEN in .env"
        start_mobile_dev
        return 0
    fi
    
    cd apps/expo
    log_success "Starting Expo server with tunnel"
    npx expo start --tunnel 2>&1 | tee ../../mobile_output.log &
    MOBILE_PID=$!
    cd ../..
    sleep 15
    
    # Wait for tunnel to be established
    log_info "Waiting for tunnel to be established..."
    sleep 10
    
    log_success "Mobile server with tunnel is running"
    log_info "Check the QR code or terminal output for tunnel URL"
    return 0
}

# Deploy to Vercel
deploy_vercel() {
    log_deploy "Starting Vercel deployment..."
    
    if ! check_token "VERCEL_TOKEN" "$VERCEL_TOKEN"; then
        log_warning "Skipping Vercel deployment - VERCEL_TOKEN not configured"
        return 1
    fi
    
    TIMEOUT=${VERCEL_TIMEOUT:-180}
    log_info "Deployment timeout: ${TIMEOUT} seconds"
    
    start_time=$(date +%s)
    timeout $TIMEOUT vercel --token "$VERCEL_TOKEN" --yes --prod 2>&1 | tee "web_output.log"
    
    if [ $? -eq 124 ]; then
        log_error "Deployment timed out"
        return 1
    fi
    
    end_time=$(date +%s)
    deployment_time=$((end_time - start_time))
    log_success "Deployment completed in ${deployment_time} seconds"
    return 0
}

# Show status
show_status() {
    log_info "Current Status"
    echo ""
    
    # Check web server
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Web server: Running on http://localhost:3000"
    else
        log_error "Web server: Not running"
    fi
    
    # Check mobile server
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        log_success "Mobile server: Running on http://localhost:8081"
    else
        log_error "Mobile server: Not running"
    fi
    
    # Check ngrok tunnels
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNELS=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); [print(f'  - {t[\"public_url\"]} -> {t[\"config\"][\"addr\"]}') for t in data['tunnels']]" 2>/dev/null || echo "Unknown")
        log_success "Ngrok tunnels:"
        echo "$TUNNELS"
        log_info "Monitor: http://localhost:4040"
    else
        log_error "Ngrok tunnels: Not running"
    fi
    
    # Show live output if available
    if [ -f "web_output.log" ]; then
        echo ""
        log_info "Recent web output:"
        tail -10 web_output.log
    fi
    
    if [ -f "mobile_output.log" ]; then
        echo ""
        log_info "Recent mobile output:"
        tail -10 mobile_output.log
    fi
}

# Show usage
show_usage() {
    echo -e "${PURPLE}🚀 T3 Turbo Deployment Script${NC}"
    echo "This script handles both web and mobile deployments with tunneling"
    echo ""
    echo -e "${GREEN}Web Commands:${NC}"
    echo "  web:dev     - Start web development server"
    echo "  web:tunnel  - Start web dev + ngrok tunnel"
    echo "  web:deploy  - Deploy web to Vercel"
    echo ""
    echo -e "${CYAN}Mobile Commands:${NC}"
    echo "  mobile:dev    - Start mobile development server"
    echo "  mobile:tunnel - Start mobile dev + Expo tunnel"
    echo "  mobile:build  - Build mobile app (development)"
    echo "  mobile:prod   - Build mobile app (production)"
    echo ""
    echo -e "${YELLOW}Complete Deployments:${NC}"
    echo "  all:web    - Complete web deployment (dev + tunnel + deploy)"
    echo "  all:mobile - Complete mobile deployment (dev + Expo tunnel + build)"
    echo ""
    echo -e "${BLUE}Utility Commands:${NC}"
    echo "  status     - Show all services status"
    echo "  clean      - Clean all live output logs"
    echo "  install:web   - Install Next.js dependencies"
    echo "  install:mobile - Install Expo dependencies"
    echo "  install:env:web   - Install environment file for web"
    echo "  install:env:mobile - Install environment file for mobile"
    echo "  configure:ngrok - Configure ngrok tunnels"
    echo "  install:ngrok - Install and configure ngrok"
    echo "  help       - Show this help"
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  - VERCEL_TOKEN: https://vercel.com/account/tokens (for web deployment)"
    echo "  - NGROK_TOKEN: https://ngrok.com/dashboard/your/authtokens (for web tunnel)"
    echo "  - EXPO_TOKEN: https://expo.dev/accounts/[username]/settings/access-tokens (optional)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./scripts/deploy.sh web:tunnel    # Web with tunnel"
    echo "  ./scripts/deploy.sh mobile:tunnel # Mobile with Expo tunnel"
    echo "  ./scripts/deploy.sh all:web       # Complete web deployment"
}

# Main script logic
load_env

case "${1:-help}" in
    # Web commands
    "web:dev")
        clean_logs "web"
        install_env_file "web"
        install_packages "web"
        start_web_dev
        log_success "Web development server started!"
        wait $WEB_PID
        ;;
    "web:tunnel")
        clean_logs "web"
        install_env_file "web"
        install_packages "web"
        install_ngrok
        start_web_dev && start_ngrok 3000
        log_success "Web development with tunnel started!"
        wait $WEB_PID $NGROK_PID
        ;;
    "web:deploy")
        clean_logs "web"
        install_env_file "web"
        install_packages "web"
        deploy_vercel
        ;;
    
    # Mobile commands
    "mobile:dev")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        start_mobile_dev
        log_success "Mobile development server started!"
        wait $MOBILE_PID
        ;;
    "mobile:tunnel")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        install_ngrok
        start_mobile_tunnel
        log_success "Mobile development with tunnel started!"
        wait $MOBILE_PID
        ;;
    "mobile:build")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        cd apps/expo && npx eas build --profile development 2>&1 | tee ../../mobile_output.log && cd ../..
        ;;
    "mobile:prod")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        cd apps/expo && npx eas build --profile production 2>&1 | tee ../../mobile_output.log && cd ../..
        ;;
    
    # Complete deployments
    "all:web")
        clean_logs "web"
        install_env_file "web"
        install_packages "web"
        install_ngrok
        start_web_dev && start_ngrok 3000 && deploy_vercel
        log_success "Complete web deployment finished!"
        ;;
    "all:mobile")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        install_ngrok
        start_mobile_tunnel
        log_success "Complete mobile deployment started!"
        wait $MOBILE_PID
        ;;
    
    # Utility commands
    "status")
        show_status
        ;;
    "clean")
        clean_logs "all"
        ;;
    "install")
        clean_logs "all"
        log_error "Please specify app type: install:web or install:mobile"
        ;;
    "install:web")
        clean_logs "web"
        install_packages "web"
        ;;
    "install:mobile")
        clean_logs "mobile"
        install_packages "mobile"
        ;;
    "install:env")
        clean_logs "all"
        log_error "Please specify app type: install:env:web or install:env:mobile"
        ;;
    "install:env:web")
        clean_logs "web"
        install_env_file "web"
        ;;
    "install:env:mobile")
        clean_logs "mobile"
        install_env_file "mobile"
        ;;
    "configure:ngrok")
        clean_logs "all"
        configure_ngrok
        ;;
    "install:ngrok")
        clean_logs "all"
        install_ngrok
        ;;
    "help"|*)
        show_usage
        ;;
esac