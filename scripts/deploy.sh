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
    rm -f live_output.log live_console.log tunnel_live.log console_output.log tunnel_output.log current_console.log deployment-*.log ngrok_output.log localtunnel_output.log
    
    # Clean app-specific logs based on app type
    case $app_type in
        "web"|"next")
            rm -f web_output.log web_tunnel_output.log
            log_success "Web logs cleaned"
            ;;
        "mobile"|"expo")
            rm -f mobile_output.log
            log_success "Mobile logs cleaned"
            ;;
        "all")
            rm -f web_output.log web_tunnel_output.log mobile_output.log
            log_success "All logs cleaned"
            ;;
        *)
            log_warning "Unknown app type for log cleaning: $app_type"
            ;;
    esac
}



# Install JavaScript packages for specific app
install_packages() {
    local app_type=$1
    log_step "Installing JavaScript packages for $app_type..."
    
    case $app_type in
        "web"|"next")
            log_info "Installing Next.js dependencies..."
            # Check if we're already in the nextjs directory
            if [ "$(basename $(pwd))" = "nextjs" ] && [ -f "package.json" ]; then
                # We're already in the nextjs directory
                pnpm install 2>&1 | tee ../../web_output.log
                if [ $? -eq 0 ]; then
                    log_success "Next.js dependencies installed"
                else
                    log_error "Failed to install Next.js dependencies"
                    return 1
                fi
            else
                # Navigate to nextjs directory from root
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
            fi
            ;;
        "mobile"|"expo")
            log_info "Installing Expo dependencies..."
            if [ -d "apps/expo" ]; then
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
            else
                pnpm install 2>&1 | tee ../mobile_output.log
                if [ $? -eq 0 ]; then
                    log_success "Expo dependencies installed"
                else
                    log_error "Failed to install Expo dependencies"
                    return 1
                fi
            fi
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

# Install environment file from .env.example and shell environment
install_env_file() {
    local app_type=${1:-"all"}
    log_step "Installing environment file for $app_type..."
    
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

    # Function to get variable value from .env file
    get_env_var_value() {
        local var_name="$1"
        grep "^${var_name}=" .env | cut -d'=' -f2- | sed 's/^["'\'']//;s/["'\'']$//'
    }

    # Function to get variable value from .env.example file
    get_example_var_value() {
        local var_name="$1"
        grep "^${var_name}=" .env.example | cut -d'=' -f2- | sed 's/^["'\'']//;s/["'\'']$//'
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

    # Check each variable and update if needed
    updated_vars=0
    for var in $env_vars; do
        shell_value=$(get_shell_var_value "$var")
        
        if var_exists_in_env "$var"; then
            # Variable exists in .env, check if it's still equal to example value
            env_value=$(get_env_var_value "$var")
            example_value=$(get_example_var_value "$var")
            
            # Check if .env value is empty, undefined, or equal to example value
            if [ -z "$env_value" ] || [ "$env_value" = "$example_value" ] || [ "$env_value" = "''" ] || [ "$env_value" = '""' ]; then
                if [ -n "$shell_value" ]; then
                    log_info "Updating variable from example value: $var"
                    remove_var_from_env "$var"
                    echo "${var}=${shell_value}" >> .env
                    updated_vars=$((updated_vars + 1))
                fi
            fi
        else
            # Variable doesn't exist in .env, add it if shell value exists
            if [ -n "$shell_value" ]; then
                log_info "Adding missing variable: $var"
                echo "${var}=${shell_value}" >> .env
                updated_vars=$((updated_vars + 1))
            fi
        fi
    done

    # Also add important shell variables that might not be in .env.example
    important_shell_vars="TUNNEL_SUBDOMAIN NGROK_TOKEN VERCEL_TOKEN EXPO_TOKEN"
    for var in $important_shell_vars; do
        shell_value=$(get_shell_var_value "$var")
        if [ -n "$shell_value" ] && ! var_exists_in_env "$var"; then
            log_info "Adding important shell variable: $var"
            echo "${var}=${shell_value}" >> .env
            updated_vars=$((updated_vars + 1))
        fi
    done

    if [ $updated_vars -gt 0 ]; then
        log_info "Added/updated $updated_vars variables from shell environment"
    else
        log_info "No environment variables needed updating"
    fi
    
    log_success "Environment file installation complete for $app_type"
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
        if ! grep -q "name: web" "$config_file"; then
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
EOF
        
        log_success "Ngrok configuration updated at $config_file"
        log_info "Web tunnel: gopher-assuring-seriously.ngrok-free.app -> http://localhost:3000"
    else
        log_info "Ngrok configuration is up to date"
    fi
    
    return 0
}

# Install and configure Vercel CLI
install_vercel() {
    log_step "Installing and configuring Vercel CLI..."
    
    # Function to get variable value from shell environment
    get_shell_var_value() {
        local var_name="$1"
        eval "echo \$${var_name}"
    }
    
    # Check if Vercel CLI is installed
    if ! command -v vercel &> /dev/null; then
        log_info "Vercel CLI not found, installing..."
        
        # Install Vercel CLI globally
        npm install -g vercel
        
        if [ $? -eq 0 ]; then
            log_success "Vercel CLI installed successfully"
        else
            log_error "Failed to install Vercel CLI"
            return 1
        fi
    else
        log_info "Vercel CLI already installed: $(vercel --version)"
    fi
    
    # Get VERCEL_TOKEN from environment
    local vercel_token=$(get_shell_var_value "VERCEL_TOKEN")
    if [ -z "$vercel_token" ]; then
        log_warning "VERCEL_TOKEN not found in environment, skipping Vercel configuration"
        return 0
    fi
    
    # Check if already logged in
    if vercel whoami &> /dev/null; then
        log_info "Vercel CLI already authenticated"
    else
        log_info "Authenticating Vercel CLI with token..."
        echo "$vercel_token" | vercel login --token
        
        if [ $? -eq 0 ]; then
            log_success "Vercel CLI authenticated successfully"
        else
            log_error "Failed to authenticate Vercel CLI"
            return 1
        fi
    fi
    
    return 0
}

# Install and configure EAS CLI
install_eas() {
    log_step "Installing and configuring EAS CLI..."
    
    # Function to get variable value from shell environment
    get_shell_var_value() {
        local var_name="$1"
        eval "echo \$${var_name}"
    }
    
    # Check if EAS CLI is installed
    if ! command -v eas &> /dev/null; then
        log_info "EAS CLI not found, installing..."
        
        # Install EAS CLI globally
        npm install -g eas-cli
        
        if [ $? -eq 0 ]; then
            log_success "EAS CLI installed successfully"
        else
            log_error "Failed to install EAS CLI"
            return 1
        fi
    else
        log_info "EAS CLI already installed: $(eas --version)"
    fi
    
    # Get EXPO_TOKEN from environment
    local expo_token=$(get_shell_var_value "EXPO_TOKEN")
    if [ -z "$expo_token" ]; then
        log_warning "EXPO_TOKEN not found in environment, EAS builds may require manual authentication"
        log_info "You can set EXPO_TOKEN for automated authentication"
        return 0
    fi
    
    # Check if already logged in
    if eas whoami &> /dev/null; then
        log_info "EAS CLI already authenticated"
    else
        log_info "Authenticating EAS CLI with token..."
        echo "$expo_token" | eas login --non-interactive
        
        if [ $? -eq 0 ]; then
            log_success "EAS CLI authenticated successfully"
        else
            log_error "Failed to authenticate EAS CLI"
            log_info "You may need to authenticate manually with: eas login"
            return 1
        fi
    fi
    
    return 0
}

# Get current IP address
get_current_ip() {
    local ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "unknown")
    echo "$ip"
}

# Get local tunnel password
get_local_tunnel_password() {
    local password=$(curl -s https://loca.lt/mytunnelpassword 2>/dev/null || echo "unknown")
    echo "$password"
}

# Install and configure Local Tunnel
install_local_tunnel() {
    log_step "Installing and configuring Local Tunnel..."
    
    # Check if localtunnel is installed globally
    if ! command -v lt &> /dev/null; then
        log_info "Local Tunnel not found, installing..."
        
        # Install localtunnel globally
        npm install -g localtunnel
        
        if [ $? -eq 0 ]; then
            log_success "Local Tunnel installed successfully"
        else
            log_error "Failed to install Local Tunnel"
            return 1
        fi
    else
        log_info "Local Tunnel already installed: $(lt --version 2>/dev/null || echo 'version unknown')"
    fi
    
    return 0
}

# Check if subdomain is available
check_subdomain_availability() {
    local subdomain=$1
    local port=${2:-3000}
    
    log_step "Checking if subdomain '$subdomain' is available..."
    
    # Start a temporary tunnel to test availability
    lt --port $port --subdomain $subdomain > /tmp/subdomain-test.log 2>&1 &
    TEMP_PID=$!
    sleep 3
    
    # Check if tunnel started successfully
    local tunnel_url="https://${subdomain}.loca.lt"
    if curl -s "$tunnel_url" > /dev/null 2>&1; then
        # Subdomain is available, kill the test tunnel
        kill $TEMP_PID 2>/dev/null || true
        rm -f /tmp/subdomain-test.log
        log_success "✅ Subdomain '$subdomain' is available"
        return 0
    else
        # Check if it failed due to subdomain already in use
        if grep -q "subdomain.*already taken" /tmp/subdomain-test.log 2>/dev/null; then
            kill $TEMP_PID 2>/dev/null || true
            rm -f /tmp/subdomain-test.log
            log_error "❌ Subdomain '$subdomain' is already taken"
            log_info "Try a different subdomain name"
            return 1
        else
            # Other error, but we'll still try to use it
            kill $TEMP_PID 2>/dev/null || true
            rm -f /tmp/subdomain-test.log
            log_warning "⚠️ Could not verify subdomain availability, but will try to use it"
            return 0
        fi
    fi
}

# Start local tunnel
start_local_tunnel() {
    local port=${1:-3000}
    local subdomain=${2:-""}
    
    log_step "Starting Local Tunnel on port $port..."
    
    # Get local tunnel password before starting and log it
    LOCAL_TUNNEL_PASSWORD=$(get_local_tunnel_password)
    echo "Local tunnel password: $LOCAL_TUNNEL_PASSWORD" | tee -a web_tunnel_output.log
    log_info "Local tunnel password: $LOCAL_TUNNEL_PASSWORD"
    
    # Check for TUNNEL_SUBDOMAIN environment variable first
    if [ -z "$subdomain" ] && [ -n "$TUNNEL_SUBDOMAIN" ]; then
        subdomain="$TUNNEL_SUBDOMAIN"
        log_info "Using TUNNEL_SUBDOMAIN from environment: $subdomain"
    fi
    
    # Generate a random subdomain if not provided
    if [ -z "$subdomain" ]; then
        subdomain="t3-turbo-$(date +%s)"
        log_info "Using random subdomain: $subdomain"
    else
        # Check if the specified subdomain is available
        if ! check_subdomain_availability "$subdomain" "$port"; then
            log_error "Cannot start tunnel - subdomain '$subdomain' is not available"
            return 1
        fi
    fi
    
    # Start local tunnel
    if [ -n "$subdomain" ]; then
        log_step "Starting tunnel with subdomain: $subdomain"
        lt --port $port --subdomain $subdomain 2>&1 | tee web_tunnel_output.log &
    else
        log_step "Starting tunnel with random subdomain"
        lt --port $port 2>&1 | tee web_tunnel_output.log &
    fi
    
    LOCAL_TUNNEL_PID=$!
    sleep 5
    
    # Get tunnel URL from log
    if [ -f web_tunnel_output.log ]; then
        TUNNEL_URL=$(grep -o 'https://[^[:space:]]*' web_tunnel_output.log | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            log_success "Local Tunnel started:"
            log_info "  - $TUNNEL_URL -> http://localhost:$port"
            return 0
        fi
    fi
    
    log_error "Failed to start Local Tunnel"
    return 1
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
    log_step "Starting ngrok tunnels..."
    
    if ! check_token "NGROK_TOKEN" "$NGROK_TOKEN"; then
        log_warning "Skipping ngrok - NGROK_TOKEN not configured"
        return 1
    fi
    
    # Start ngrok with web tunnel only
    ngrok start web 2>&1 | tee web_tunnel_output.log &
    NGROK_PID=$!
    sleep 5
    
    # Get tunnel URLs
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNELS=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); [print(f'  - {t[\"public_url\"]} -> {t[\"config\"][\"addr\"]}') for t in data['tunnels']]" 2>/dev/null || echo "Unknown")
        log_success "Ngrok tunnels started:"
        echo "$TUNNELS"
        log_info "Monitor: http://localhost:4040"
        return 0
    else
        log_error "Failed to start ngrok tunnels"
        return 1
    fi
}

# Start web development server
start_web_dev() {
    local use_tunnel=${1:-false}
    local tunnel_type=${2:-"local"}
    log_step "Starting web development server..."
    
    log_success "Starting web server on http://localhost:3000"
    pnpm -F @acme/nextjs dev 2>&1 | tee web_output.log &
    WEB_PID=$!
    sleep 10
    
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Web server is running"
        
        if [ "$use_tunnel" = true ]; then
            case $tunnel_type in
                "ngrok")
                    log_step "Starting ngrok tunnels..."
                    start_ngrok
                    if [ $? -eq 0 ]; then
                        log_success "Web server with ngrok tunnel is running"
                    else
                        log_warning "Web server running without tunnel"
                    fi
                    ;;
                "local")
                    log_step "Starting local tunnel..."
                    start_local_tunnel 3000
                    if [ $? -eq 0 ]; then
                        log_success "Web server with local tunnel is running"
                    else
                        log_warning "Web server running without tunnel"
                    fi
                    ;;
                *)
                    log_error "Unknown tunnel type: $tunnel_type"
                    return 1
                    ;;
            esac
        fi
        
        return 0
    else
        log_error "Failed to start web server"
        return 1
    fi
}

# Start mobile development server
start_mobile_dev() {
    local use_tunnel=${1:-false}
    log_step "Starting mobile development server..."
    
    if [ "$use_tunnel" = true ]; then
        log_success "Starting Expo server with tunnel"
        pnpm -F @acme/expo dev:tunnel 2>&1 | tee mobile_output.log &
        MOBILE_PID=$!
        sleep 15
        
        # Wait for tunnel to be established
        log_info "Waiting for tunnel to be established..."
        sleep 10
        
        log_success "Mobile server with tunnel is running"
        log_info "Check the QR code or terminal output for tunnel URL"
    else
        log_success "Starting Expo server on http://localhost:8081"
        pnpm -F @acme/expo dev 2>&1 | tee mobile_output.log &
        MOBILE_PID=$!
        sleep 10
        
        if curl -s http://localhost:8081 > /dev/null 2>&1; then
            log_success "Mobile server is running"
        else
            log_error "Failed to start mobile server"
            return 1
        fi
    fi
    
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

# Get PID of a process by pattern
get_pid() {
    local pattern=$1
    pgrep -f "$pattern" | head -1
}

# Get multiple PIDs of processes by pattern
get_pids() {
    local pattern=$1
    pgrep -f "$pattern" | tr '\n' ' ' | sed 's/ $//'
}

# Get process names with PIDs
get_process_names() {
    local pattern=$1
    local category=$2
    local pids=$(pgrep -f "$pattern")
    if [ -n "$pids" ]; then
        echo "$pids" | while read pid; do
            local args=$(ps -p "$pid" -o args= 2>/dev/null | head -1)
            if [ -n "$args" ]; then
                # Show the first part of the command (truncated if too long)
                local cmd=$(echo "$args" | cut -d' ' -f1-3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [ ${#cmd} -gt 50 ]; then
                    cmd=$(echo "$cmd" | cut -c1-47)"..."
                fi
                echo "    $pid ($cmd)"
            else
                echo "    $pid"
            fi
        done
    fi
}



# Show status
show_status() {
    log_info "Current Status"
    echo ""
    
    # Get current IP address
    CURRENT_IP=$(get_current_ip)
    log_info "Current IP Address: $CURRENT_IP"
    echo ""
    
    # Check web server
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        WEB_PID=$(get_pid "next dev")
        if [ -n "$WEB_PID" ]; then
            log_success "Web server: Running on http://localhost:3000 (PID: $WEB_PID)"
        else
            log_success "Web server: Running on http://localhost:3000"
        fi
    else
        log_error "Web server: Not running"
    fi
    
    # Check mobile server
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        MOBILE_PID=$(get_pid "expo start")
        if [ -n "$MOBILE_PID" ]; then
            log_success "Mobile server: Running on http://localhost:8081 (PID: $MOBILE_PID)"
        else
            log_success "Mobile server: Running on http://localhost:8081"
        fi
    else
        log_error "Mobile server: Not running"
    fi
    
    # Check ngrok tunnels
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        NGROK_PID=$(get_pid "ngrok")
        NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data['tunnels'] else '')" 2>/dev/null || echo "")
        if [ -n "$NGROK_PID" ] && [ -n "$NGROK_URL" ]; then
            log_success "Ngrok tunnel: $NGROK_URL (PID: $NGROK_PID)"
        elif [ -n "$NGROK_PID" ]; then
            log_success "Ngrok tunnels: (PID: $NGROK_PID)"
        else
            log_success "Ngrok tunnels:"
        fi
        if [ -n "$NGROK_URL" ]; then
            log_info "  - $NGROK_URL -> http://localhost:3000"
        fi
        log_info "Monitor: http://localhost:4040"
    else
        log_error "Ngrok tunnels: Not running"
    fi
    
    # Check local tunnel
    LOCAL_TUNNEL_PID=$(get_pid "lt --port")
    if [ -n "$LOCAL_TUNNEL_PID" ]; then
        # Check if custom subdomain is configured and working
        if [ -n "$TUNNEL_SUBDOMAIN" ]; then
            CUSTOM_URL="https://${TUNNEL_SUBDOMAIN}.loca.lt"
            if curl -s "$CUSTOM_URL" > /dev/null 2>&1; then
                LOCAL_TUNNEL_URL="$CUSTOM_URL"
                log_success "Local tunnel:"
                log_info "  - $LOCAL_TUNNEL_URL -> http://localhost:3000 (custom subdomain)"
            else
                # Fallback to log file if custom subdomain not working
                if [ -f "web_tunnel_output.log" ]; then
                    LOCAL_TUNNEL_URL=$(grep -o 'https://[^[:space:]]*\.loca\.lt' web_tunnel_output.log | head -1)
                fi
                if [ -n "$LOCAL_TUNNEL_URL" ]; then
                    log_success "Local tunnel:"
                    log_info "  - $LOCAL_TUNNEL_URL -> http://localhost:3000"
                else
                    log_error "Local tunnel: Not running"
                fi
            fi
        else
            # No custom subdomain, use log file
            if [ -f "web_tunnel_output.log" ]; then
                LOCAL_TUNNEL_URL=$(grep -o 'https://[^[:space:]]*\.loca\.lt' web_tunnel_output.log | head -1)
            fi
            if [ -n "$LOCAL_TUNNEL_URL" ]; then
                log_success "Local tunnel:"
                log_info "  - $LOCAL_TUNNEL_URL -> http://localhost:3000"
            else
                log_error "Local tunnel: Not running"
            fi
        fi
        
        if [ -n "$LOCAL_TUNNEL_URL" ]; then
            log_info "  - PID: $LOCAL_TUNNEL_PID"
            # Display stored local tunnel password
            if [ -n "$LOCAL_TUNNEL_PASSWORD" ]; then
                log_warning "  Password: $LOCAL_TUNNEL_PASSWORD"
            else
                # Fallback to fetching password if not stored
                LOCAL_TUNNEL_PASSWORD=$(get_local_tunnel_password)
                log_warning "  Password: $LOCAL_TUNNEL_PASSWORD"
            fi
        fi
    else
        log_error "Local tunnel: Not running"
    fi
    
    # Show process details
    echo ""
    log_info "Process Details:"
    
    # Web processes
    WEB_PIDS=$(get_pids "next dev|pnpm -F @acme/nextjs")
    if [ -n "$WEB_PIDS" ]; then
        log_info "  Web processes:"
        get_process_names "next dev|pnpm -F @acme/nextjs"
    fi
    
    # Mobile processes
    MOBILE_PIDS=$(get_pids "expo start|pnpm -F @acme/expo")
    if [ -n "$MOBILE_PIDS" ]; then
        log_info "  Mobile processes:"
        get_process_names "expo start|pnpm -F @acme/expo"
    fi
    
    # Tunnel processes
    TUNNEL_PIDS=$(get_pids "lt --port|ngrok")
    if [ -n "$TUNNEL_PIDS" ]; then
        log_info "  Tunnel processes:"
        get_process_names "lt --port|ngrok"
    fi
    
    # Show live output if available
    if [ -f "web_output.log" ]; then
        echo ""
        log_info "Recent web output:"
        tail -10 web_output.log
    fi
    
    if [ -f "web_tunnel_output.log" ]; then
        echo ""
        log_info "Recent tunnel output:"
        tail -10 web_tunnel_output.log
    fi
    
    if [ -f "mobile_output.log" ]; then
        echo ""
        log_info "Recent mobile output:"
        tail -10 mobile_output.log
    fi
}

# Stop development servers
stop_servers() {
    local target=${1:-"all"}
    
    case $target in
        "web")
            log_step "Stopping web development servers..."
            
            # Kill Next.js processes
            if pkill -f "next dev" 2>/dev/null; then
                log_success "Next.js development server stopped"
            else
                log_warning "No Next.js development server found"
            fi
            
            # Kill pnpm processes for web
            if pkill -f "pnpm -F @acme/nextjs" 2>/dev/null; then
                log_success "pnpm web processes stopped"
            fi
            
            # Kill local tunnel processes
            if pkill -f "localtunnel\|lt --port" 2>/dev/null; then
                log_success "Local tunnel stopped"
            fi
            
            # Kill ngrok processes for web
            if pkill -f "ngrok.*3000\|ngrok.*3001" 2>/dev/null; then
                log_success "Ngrok tunnel for web stopped"
            fi
            
            log_success "Web development servers stopped"
            ;;
            
        "mobile")
            log_step "Stopping mobile development servers..."
            
            # Kill Expo processes
            if pkill -f "expo start" 2>/dev/null; then
                log_success "Expo development server stopped"
            else
                log_warning "No Expo development server found"
            fi
            
            # Kill pnpm processes for mobile
            if pkill -f "pnpm -F @acme/expo" 2>/dev/null; then
                log_success "pnpm mobile processes stopped"
            fi
            
            # Kill ngrok processes for mobile
            if pkill -f "ngrok.*8081" 2>/dev/null; then
                log_success "Ngrok tunnel for mobile stopped"
            fi
            
            log_success "Mobile development servers stopped"
            ;;
            
        "all")
            log_step "Stopping all development servers..."
            
            # Stop web servers
            stop_servers "web"
            
            # Stop mobile servers
            stop_servers "mobile"
            
            # Kill any remaining pnpm processes
            if pkill -f "pnpm -F" 2>/dev/null; then
                log_success "Remaining pnpm processes stopped"
            fi
            
            log_success "All development servers stopped"
            ;;
            
        *)
            log_error "Invalid target: $target. Use 'web', 'mobile', or 'all'"
            return 1
            ;;
    esac
}

# Show usage
show_usage() {
    echo -e "${PURPLE}🚀 T3 Turbo Deployment Script${NC}"
    echo "This script handles both web and mobile deployments with tunneling"
    echo ""
    echo -e "${GREEN}Web Commands:${NC}"
    echo "  web:dev        - Start web development server"
    echo "  web:tunnel     - Start web dev + local tunnel (default)"

    echo "  web:ngrok-tunnel - Start web dev + ngrok tunnel"
    echo "  web:vercel     - Deploy web to Vercel"
    echo ""
    echo -e "${CYAN}Mobile Commands:${NC}"
    echo "  mobile:dev    - Start mobile development server"
    echo "  mobile:tunnel - Start mobile dev + Expo tunnel"
    echo "  mobile:all    - EAS build for all platforms"
    echo "  mobile:android - EAS build for Android"
    echo "  mobile:ios    - EAS build for iOS"
    echo ""
    echo -e "${YELLOW}Complete Deployments:${NC}"
    echo "  all:local     - Complete local development (web + mobile)"
    echo "  all:tunnel    - Complete tunnel development (web + mobile)"
    echo "  all:build     - Complete build (Vercel + EAS)"
    echo ""
    echo -e "${RED}Stop Commands:${NC}"
    echo "  stop:web      - Stop web development servers"
    echo "  stop:mobile   - Stop mobile development servers"
    echo "  stop:all      - Stop all development servers"
    echo ""
    echo -e "${BLUE}Utility Commands:${NC}"
    echo "  status     - Show all services status"
    echo "  clean      - Clean all live output logs"
    echo "  install:web   - Install Next.js dependencies"
    echo "  install:mobile - Install Expo dependencies"
    echo "  install:env:web   - Install environment file for web"
    echo "  install:env:mobile - Install environment file for mobile"
    echo "  install:ngrok - Install and configure ngrok"
    echo "  help       - Show this help"
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  - VERCEL_TOKEN: https://vercel.com/account/tokens (for web deployment)"
    echo "  - NGROK_TOKEN: https://ngrok.com/dashboard/your/authtokens (for ngrok tunnel)"
    echo "  - EXPO_TOKEN: https://expo.dev/accounts/[username]/settings/access-tokens (optional)"
    echo ""
    echo -e "${YELLOW}Local Tunnel:${NC}"
    echo "  - Password is automatically fetched from https://loca.lt/mytunnelpassword"
    echo "  - No additional configuration required"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./scripts/deploy.sh web:tunnel        # Web with local tunnel (default)"

    echo "  ./scripts/deploy.sh web:ngrok-tunnel  # Web with ngrok tunnel"
    echo "  ./scripts/deploy.sh mobile:tunnel     # Mobile with Expo tunnel"
    echo "  ./scripts/deploy.sh all:local         # Complete local development"
    echo "  ./scripts/deploy.sh all:tunnel        # Complete tunnel development"
    echo "  ./scripts/deploy.sh all:build         # Complete build (Vercel + EAS)"
    echo "  ./scripts/deploy.sh stop:all          # Stop all development servers"
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
        install_local_tunnel
        start_web_dev true "local"
        log_success "Web development with local tunnel started!"
        wait $WEB_PID $LOCAL_TUNNEL_PID
        ;;

    "web:ngrok-tunnel")
        clean_logs "web"
        install_env_file "web"
        install_packages "web"
        install_ngrok
        start_web_dev true "ngrok"
        log_success "Web development with ngrok tunnel started!"
        wait $WEB_PID $NGROK_PID
        ;;
    "web:vercel")
        clean_logs "web"
        install_env_file "web"
        install_packages "web"
        install_vercel
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
        start_mobile_dev true
        log_success "Mobile development with tunnel started!"
        wait $MOBILE_PID
        ;;
    # EAS deployments
    "mobile:all")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        install_eas
        log_step "Starting EAS build for all platforms..."
        pnpm -F @acme/expo build 2>&1 | tee mobile_output.log
        log_success "EAS build for all platforms completed!"
        ;;
    "mobile:android")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        install_eas
        log_step "Starting EAS build for Android..."
        pnpm -F @acme/expo build:android 2>&1 | tee mobile_output.log
        log_success "EAS build for Android completed!"
        ;;
    "mobile:ios")
        clean_logs "mobile"
        install_env_file "mobile"
        install_packages "mobile"
        install_eas
        log_step "Starting EAS build for iOS..."
        pnpm -F @acme/expo build:ios 2>&1 | tee mobile_output.log
        log_success "EAS build for iOS completed!"
        ;;
    
    # Complete deployments
    "all:local")
        clean_logs "all"
        install_env_file "web"
        install_env_file "mobile"
        install_packages "web"
        install_packages "mobile"
        start_web_dev true "local"
        start_mobile_dev true
        log_success "Complete local development started!"
        wait $WEB_PID $MOBILE_PID
        ;;
    "all:tunnel")
        clean_logs "all"
        install_env_file "web"
        install_env_file "mobile"
        install_packages "web"
        install_packages "mobile"
        install_local_tunnel
        install_ngrok
        start_web_dev true "local"
        start_mobile_dev true
        log_success "Complete tunnel development started!"
        wait $WEB_PID $MOBILE_PID $LOCAL_TUNNEL_PID
        ;;
    "all:build")
        clean_logs "all"
        install_env_file "web"
        install_env_file "mobile"
        install_packages "web"
        install_packages "mobile"
        install_vercel
        install_eas
        log_step "Starting complete build (Vercel + EAS)..."
        deploy_vercel
        log_step "Starting EAS build for all platforms..."
        pnpm -F @acme/expo build 2>&1 | tee mobile_output.log
        log_success "Complete build (Vercel + EAS) finished!"
        ;;
    
    # Stop commands
    "stop:web")
        stop_servers "web"
        ;;
    "stop:mobile")
        stop_servers "mobile"
        ;;
    "stop:all")
        stop_servers "all"
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
    "install:ngrok")
        clean_logs "all"
        install_ngrok
        ;;
    "help"|*)
        show_usage
        ;;
esac