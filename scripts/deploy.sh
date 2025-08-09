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
    log_step "Cleaning live output logs..."
    rm -f live_output.log live_console.log tunnel_live.log console_output.log tunnel_output.log current_console.log
    rm -f deployment-*.log
    log_success "Live output logs cleaned"
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
    ngrok http $port 2>&1 | tee live_output.log &
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
    pnpm dev:next 2>&1 | tee live_output.log &
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
    expo start --lan 2>&1 | tee ../live_output.log &
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
    expo start --tunnel 2>&1 | tee ../live_output.log &
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
    timeout $TIMEOUT vercel --token "$VERCEL_TOKEN" --yes --prod 2>&1 | tee "live_output.log"
    
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
    if [ -f "live_output.log" ]; then
        echo ""
        log_info "Recent live output:"
        tail -10 live_output.log
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
        clean_logs
        start_web_dev
        log_success "Web development server started!"
        log_info "Live output: cat live_output.log"
        wait $WEB_PID
        ;;
    "web:tunnel")
        clean_logs
        start_web_dev && start_ngrok 3000
        log_success "Web development with tunnel started!"
        log_info "Live output: cat live_output.log"
        wait $WEB_PID $NGROK_PID
        ;;
    "web:deploy")
        clean_logs
        deploy_vercel
        log_info "Live output: cat live_output.log"
        ;;
    
    # Mobile commands
    "mobile:dev")
        clean_logs
        start_mobile_dev
        log_success "Mobile development server started!"
        log_info "Live output: cat live_output.log"
        wait $MOBILE_PID
        ;;
    "mobile:tunnel")
        clean_logs
        start_mobile_tunnel
        log_success "Mobile development with tunnel started!"
        log_info "Live output: cat live_output.log"
        wait $MOBILE_PID
        ;;
    "mobile:build")
        clean_logs
        cd apps/expo && eas build --profile development 2>&1 | tee ../live_output.log && cd ../..
        log_info "Live output: cat live_output.log"
        ;;
    "mobile:prod")
        clean_logs
        cd apps/expo && eas build --profile production 2>&1 | tee ../live_output.log && cd ../..
        log_info "Live output: cat live_output.log"
        ;;
    
    # Complete deployments
    "all:web")
        clean_logs
        start_web_dev && start_ngrok 3000 && deploy_vercel
        log_success "Complete web deployment finished!"
        log_info "Live output: cat live_output.log"
        ;;
    "all:mobile")
        clean_logs
        start_mobile_tunnel
        log_success "Complete mobile deployment started!"
        log_info "Live output: cat live_output.log"
        wait $MOBILE_PID
        ;;
    
    # Utility commands
    "status")
        show_status
        ;;
    "clean")
        clean_logs
        ;;
    "help"|*)
        show_usage
        ;;
esac