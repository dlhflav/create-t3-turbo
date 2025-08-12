#!/bin/bash

set -e

# Colors and logging
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'
log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}🔧 $1${NC}"; }

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Clean logs
clean_logs() {
    local app_type=${1:-"all"}
    case $app_type in 
        "web") rm -f web_output.log web_tunnel_output.log ;;
        "mobile") rm -f mobile_output.log ;;
        "all") rm -f web_output.log web_tunnel_output.log mobile_output.log ;;
    esac
    log_success "Logs cleaned for $app_type"
}

# Install packages
install_packages() {
    local app_type=$1
    log_step "Installing $app_type dependencies..."
    
    case $app_type in
        "web") pnpm install -F @acme/nextjs ;;
        "mobile") pnpm install -F @acme/expo ;;
    esac
    log_success "$app_type dependencies installed"
}

# Environment management
load_env() {
    [ -f .env ] && export $(grep -E '^(VERCEL_TOKEN|NGROK_TOKEN|EXPO_TOKEN|TUNNEL_SUBDOMAIN)=' .env | xargs)
}

get_env_value() {
    local var_name="$1"
    local env_value=$(grep "^${var_name}=" .env 2>/dev/null | cut -d'=' -f2- | sed 's/^["'\'']//;s/["'\'']$//')
    local shell_value=$(eval "echo \$${var_name}")
    local example_value=$(grep "^${var_name}=" .env.example 2>/dev/null | cut -d'=' -f2- | sed 's/^["'\'']//;s/["'\'']$//')
    
    [ -n "$env_value" ] && [ "$env_value" != "$example_value" ] && echo "$env_value" && return 0
    [ -n "$shell_value" ] && echo "$shell_value" && return 0
    [ -n "$example_value" ] && echo "$example_value" && return 0
    echo ""
}

# Install tools
install_tool() {
    local tool=$1
    local install_cmd=$2
    
    if ! command -v $tool &> /dev/null; then
        log_info "Installing $tool..."
        eval $install_cmd
        log_success "$tool installed"
    else
        log_info "$tool already installed"
    fi
    
    # Configure if needed
    case $tool in
        "ngrok")
            local token=$(get_env_value "NGROK_TOKEN")
            [ -n "$token" ] && mkdir -p ~/.config/ngrok && echo "authtoken: $token" > ~/.config/ngrok/ngrok.yml
            ;;
        "vercel")
            local token=$(get_env_value "VERCEL_TOKEN")
            [ -n "$token" ] && echo "$token" | vercel login --token
            ;;
        "eas")
            local token=$(get_env_value "EXPO_TOKEN")
            [ -n "$token" ] && echo "$token" | eas login --non-interactive
            ;;
    esac
}

# =============================================================================
# SERVICE DETECTION FUNCTIONS
# =============================================================================

# Web server detection
is_web_running() {
    pgrep -f "next dev" >/dev/null 2>&1 || pgrep -f "next-server" >/dev/null 2>&1 || pgrep -f "pnpm -F @acme/nextjs" >/dev/null 2>&1
}

get_web_info() {
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "http://localhost:3000"
    else
        echo "unknown"
    fi
}

# Mobile server detection
is_mobile_running() {
    pgrep -f "expo start" >/dev/null 2>&1 || pgrep -f "pnpm -F @acme/expo" >/dev/null 2>&1
}

get_mobile_info() {
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        # Check if mobile is running in tunnel mode by looking for ngrok tunnel
        if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
            local tunnel_url=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); tunnels=data.get('tunnels', []); mobile_tunnel=next((t['public_url'] for t in tunnels if t['public_url'].endswith('8081.exp.direct')), ''); print(mobile_tunnel)" 2>/dev/null)
            if [ -n "$tunnel_url" ]; then
                echo "$tunnel_url"
                return 0
            fi
        fi
        echo "http://localhost:8081"
    else
        echo "unknown"
    fi
}

# Tunnel detection
is_local_tunnel_running() {
    pgrep -f "lt --port" >/dev/null 2>&1
}

get_local_tunnel_info() {
    if [ -f web_tunnel_output.log ]; then
        local url=$(grep -o 'https://[^[:space:]]*' web_tunnel_output.log | head -1)
        if [ -n "$url" ]; then
            echo "$url"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

is_ngrok_running() {
    pgrep -f "ngrok" >/dev/null 2>&1
}

get_ngrok_info() {
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        local url=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data['tunnels'] else '')" 2>/dev/null)
        if [ -n "$url" ]; then
            echo "$url"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# =============================================================================
# TUNNEL FUNCTIONS
# =============================================================================

start_local_tunnel() {
    if is_local_tunnel_running; then
        local url=$(get_local_tunnel_info)
        log_info "Local tunnel is already running at $url, skipping..."
        return 0
    fi

    log_info "Starting local tunnel in background (logs: web_tunnel_output.log)..."
    install_tool "lt" "npm install -g localtunnel"

    local port=${1:-3000}
    local subdomain=${2:-$(get_env_value "TUNNEL_SUBDOMAIN")}
    [ -z "$subdomain" ] && subdomain="t3-turbo-$(date +%s)"

    rm -f web_tunnel_output.log
    lt --port $port --subdomain $subdomain > web_tunnel_output.log 2>&1 &
    log_info "Waiting 5 seconds for local tunnel to start..."
    sleep 5
    
    if [ -f web_tunnel_output.log ]; then
        local tunnel_url=$(grep -o 'https://[^[:space:]]*' web_tunnel_output.log | head -1)
        if [ -n "$tunnel_url" ]; then
            # Check for URL mismatch
            if [ -n "$subdomain" ]; then
                local expected_url="https://${subdomain}.loca.lt"
                [ "$tunnel_url" != "$expected_url" ] && log_warning "URL mismatch: Expected $expected_url, got $tunnel_url"
            fi
            log_success "Local tunnel: $tunnel_url -> http://localhost:$port"
            return 0
        fi
    fi
    log_error "Failed to start local tunnel"
    return 1
}

start_ngrok() {
    if is_ngrok_running; then
        local url=$(get_ngrok_info)
        log_info "Ngrok is already running at $url, skipping..."
        return 0
    fi
    
    log_info "Starting ngrok in background (logs: web_tunnel_output.log)..."
    install_tool "ngrok" "curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null && sudo apt update && sudo apt install -y ngrok"
    
    local token=$(get_env_value "NGROK_TOKEN")
    [ -z "$token" ] && log_warning "NGROK_TOKEN not set" && return 1
    
    rm -f web_tunnel_output.log
    ngrok start web > web_tunnel_output.log 2>&1 &
    log_info "Waiting 5 seconds for ngrok to start..."
    sleep 5
    
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        local url=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data['tunnels'] else '')" 2>/dev/null)
        log_success "Ngrok tunnel: $url -> http://localhost:3000"
        return 0
    fi
    log_error "Failed to start ngrok"
    return 1
}

# =============================================================================
# DEVELOPMENT SERVER FUNCTIONS
# =============================================================================

start_web_dev() {
    local use_tunnel=${1:-false}
    local tunnel_type=${2:-"local"}

    if is_web_running; then
        local url=$(get_web_info)
        log_info "Web server is already running at $url, skipping..."
        [ "$use_tunnel" = true ] && {
            case $tunnel_type in
                "ngrok") start_ngrok ;;
                "local") start_local_tunnel 3000 ;;
            esac
        }
        return 0
    fi
    
    log_info "Starting web server in background (logs: web_output.log)..."
    rm -f web_output.log
    pnpm -F @acme/nextjs dev > web_output.log 2>&1 &
    log_info "Waiting 5 seconds for web server to start..."
    sleep 5
    
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Web server running on http://localhost:3000"
        [ "$use_tunnel" = true ] && {
            case $tunnel_type in
                "ngrok") start_ngrok ;;
                "local") start_local_tunnel 3000 ;;
            esac
        }
        return 0
    fi
    log_error "Failed to start web server"
    return 1
}

start_mobile_dev() {
    local use_tunnel=${1:-false}

    if is_mobile_running; then
        local url=$(get_mobile_info)
        log_info "Mobile server is already running at $url, skipping..."
        return 0
    fi
    
    log_info "Starting mobile server in background (logs: mobile_output.log)..."
    rm -f mobile_output.log
    
    if [ "$use_tunnel" = true ]; then
        pnpm -F @acme/expo dev:tunnel > mobile_output.log 2>&1 &
        log_info "Waiting 5 seconds for mobile server to start..."
        sleep 5
        
        # Try to extract tunnel URL from ngrok API (expo uses ngrok internally)
        sleep 2  # Give ngrok a moment to start
        if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
            local tunnel_url=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); tunnels=data.get('tunnels', []); mobile_tunnel=next((t['public_url'] for t in tunnels if t['public_url'].endswith('8081.exp.direct')), ''); print(mobile_tunnel)" 2>/dev/null)
            if [ -n "$tunnel_url" ]; then
                log_success "Mobile server started with tunnel: $tunnel_url"
                return 0
            fi
        fi
        log_success "Mobile server started (tunnel mode)"
    else
        pnpm -F @acme/expo dev > mobile_output.log 2>&1 &
        log_info "Waiting 5 seconds for mobile server to start..."
        sleep 5
        log_success "Mobile server started"
    fi
}

# =============================================================================
# DEPLOYMENT FUNCTIONS
# =============================================================================

deploy_vercel() {
    log_step "Deploying to Vercel..."
    install_tool "vercel" "npm install -g vercel"
    
    local token=$(get_env_value "VERCEL_TOKEN")
    [ -z "$token" ] && log_error "VERCEL_TOKEN not set" && return 1
    
    timeout ${VERCEL_TIMEOUT:-180} vercel --token "$token" --yes --prod
    log_success "Vercel deployment completed"
}

deploy_mobile() {
    local platform=${1:-"all"}
    log_step "Building mobile app for $platform..."
    install_tool "eas" "npm install -g eas-cli"
    
    case $platform in
        "android") pnpm -F @acme/expo build:android ;;
        "ios") pnpm -F @acme/expo build:ios ;;
        *) pnpm -F @acme/expo build ;;
    esac
    log_success "Mobile build completed"
}

# =============================================================================
# STATUS AND CONTROL FUNCTIONS
# =============================================================================

show_status() {
    log_info "Current Status:"
    echo ""
    
    # Web server
    if is_web_running; then
        local url=$(get_web_info)
        local pid=$(pgrep -f "next dev" | head -1)
        log_success "Web server: Running on $url${pid:+ (PID: $pid)}"
    else
        log_error "Web server: Not running"
    fi
    
    # Mobile server
    if is_mobile_running; then
        local url=$(get_mobile_info)
        local pid=$(pgrep -f "expo start" | head -1)
        log_success "Mobile server: Running on $url${pid:+ (PID: $pid)}"
    else
        log_error "Mobile server: Not running"
    fi
    
    # Tunnels
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        local url=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data['tunnels'] else '')" 2>/dev/null)
        [ -n "$url" ] && log_success "Ngrok tunnel: $url"
    fi
    
    if is_local_tunnel_running; then
        local url=$(get_local_tunnel_info)
        [ "$url" != "unknown" ] && log_success "Local tunnel: $url"
    fi
    
    # Process list
    echo ""
    log_info "Running Processes:"
    
    # Web processes
    local next_pids=$(pgrep -f "next dev")
    local next_server_pids=$(pgrep -f "next-server")
    local pnpm_next_pids=$(pgrep -f "pnpm -F @acme/nextjs")
    local lt_pids=$(pgrep -f "lt --port")
    local ngrok_pids=$(pgrep -f "ngrok")
    
    if [ -n "$next_pids" ] || [ -n "$next_server_pids" ] || [ -n "$pnpm_next_pids" ] || [ -n "$lt_pids" ] || [ -n "$ngrok_pids" ]; then
        for pid in $next_pids $next_server_pids $pnpm_next_pids $lt_pids $ngrok_pids; do
            local cmd=$(ps -p "$pid" -o args= 2>/dev/null | head -1)
            [ -n "$cmd" ] && echo "  $pid: $cmd"
        done | sort -u
    fi
    
    # Mobile processes
    local expo_pids=$(pgrep -f "expo start")
    local pnpm_expo_pids=$(pgrep -f "pnpm -F @acme/expo")
    
    if [ -n "$expo_pids" ] || [ -n "$pnpm_expo_pids" ]; then
        for pid in $expo_pids $pnpm_expo_pids; do
            local cmd=$(ps -p "$pid" -o args= 2>/dev/null | head -1)
            [ -n "$cmd" ] && echo "  $pid: $cmd"
        done | sort -u
    fi
    
    # Show if no processes found
    if [ -z "$next_pids" ] && [ -z "$next_server_pids" ] && [ -z "$pnpm_next_pids" ] && [ -z "$lt_pids" ] && [ -z "$ngrok_pids" ] && [ -z "$expo_pids" ] && [ -z "$pnpm_expo_pids" ]; then
        log_warning "No development processes found"
    fi
}

stop_servers() {
    local target=${1:-"all"}
    log_step "Stopping $target servers..."
    
    case $target in
        "web")
            pkill -f "next dev" 2>/dev/null || true
            pkill -f "next-server" 2>/dev/null || true
            pkill -f "pnpm -F @acme/nextjs" 2>/dev/null || true
            pkill -f "lt --port" 2>/dev/null || true
            pkill -f "ngrok" 2>/dev/null || true
            clean_logs "web"
            ;;
        "mobile")
            pkill -f "expo start" 2>/dev/null || true
            pkill -f "pnpm -F @acme/expo" 2>/dev/null || true
            clean_logs "mobile"
            ;;
        "all")
            pkill -f "next dev" 2>/dev/null || true
            pkill -f "next-server" 2>/dev/null || true
            pkill -f "expo start" 2>/dev/null || true
            pkill -f "pnpm -F @acme" 2>/dev/null || true
            pkill -f "lt --port" 2>/dev/null || true
            pkill -f "ngrok" 2>/dev/null || true
            clean_logs "all"
            ;;
    esac
    log_success "$target servers stopped"
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

load_env

case "${1:-help}" in
    # Web commands
    "web:dev")
        install_packages "web"
        start_web_dev
        ;;
    "web:tunnel")
        install_packages "web"
        start_web_dev true "local"
        ;;
    "web:ngrok-tunnel")
        install_packages "web"
        start_web_dev true "ngrok"
        ;;
    "web:vercel")
        install_packages "web"
        deploy_vercel
        ;;
    
    # Mobile commands
    "mobile:dev")
        install_packages "mobile"
        start_mobile_dev
        ;;
    "mobile:tunnel")
        install_packages "mobile"
        start_mobile_dev true
        ;;
    "mobile:android"|"mobile:ios"|"mobile:all")
        install_packages "mobile"
        deploy_mobile "${1#mobile:}"
        ;;
    
    # Combined commands
    "all:local")
        install_packages "web"
        install_packages "mobile"
        start_web_dev true "local"
        start_mobile_dev true
        ;;
    "all:tunnel")
        install_packages "web"
        install_packages "mobile"
        start_web_dev true "local"
        start_mobile_dev true
        ;;
    "all:build")
        install_packages "web"
        install_packages "mobile"
        deploy_vercel
        deploy_mobile
        ;;
    
    # Control commands
    "stop:web"|"stop:mobile"|"stop:all")
        stop_servers "${1#stop:}"
        ;;
    
    # Utility commands
    "status")
        show_status
        ;;
    "clean")
        clean_logs "all"
        ;;
    "install:web"|"install:mobile")
        install_packages "${1#install:}"
        ;;
    "install:ngrok"|"install:vercel"|"install:eas")
        install_tool "${1#install:}" "npm install -g ${1#install:}-cli"
        ;;
    "help"|*)
        echo -e "${PURPLE}🚀 T3 Turbo Deployment Script${NC}"
        echo ""
        echo -e "${GREEN}Web:${NC} web:dev, web:tunnel, web:ngrok-tunnel, web:vercel"
        echo -e "${CYAN}Mobile:${NC} mobile:dev, mobile:tunnel, mobile:android, mobile:ios, mobile:all"
        echo -e "${YELLOW}Combined:${NC} all:local, all:tunnel, all:build"
        echo -e "${RED}Stop:${NC} stop:web, stop:mobile, stop:all"
        echo -e "${BLUE}Utils:${NC} status, clean, install:web, install:mobile"
        echo ""
        echo -e "${YELLOW}Examples:${NC}"
        echo "  ./scripts/deploy.sh web:tunnel     # Web with local tunnel"
        echo "  ./scripts/deploy.sh mobile:tunnel  # Mobile with Expo tunnel"
        echo "  ./scripts/deploy.sh all:local      # Complete local development"
        echo "  ./scripts/deploy.sh stop:all       # Stop all servers"
        ;;
esac