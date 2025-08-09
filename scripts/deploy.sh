#!/bin/bash

# T3 Turbo Deployment Script
# This script handles both development (ngrok) and production (Vercel) deployments

set -e  # Exit on any error

# Source common utilities
source "$(dirname "$0")/simple-utils.sh"

# Load environment variables (simplified)
if [ -f .env ]; then
    echo -e "${BLUE}ℹ️ Loading environment variables...${NC}"
    # Only load specific variables we need
    export VERCEL_TOKEN=$(grep VERCEL_TOKEN .env | cut -d'=' -f2 | tr -d '"')
    export NGROK_AUTHTOKEN=$(grep NGROK_AUTHTOKEN .env | cut -d'=' -f2 | tr -d '"')
else
    echo -e "${YELLOW}⚠️ .env file not found, using environment variables${NC}"
fi

# Function to check if token is set
check_token() {
    local token_name=$1
    local token_value=$2
    
    if [ -z "$token_value" ] || [ "$token_value" = "your-$token_name-here" ]; then
        log_error "$token_name not set in .env file"
        return 1
    fi
    return 0
}

# Function to deploy to Vercel
deploy_vercel() {
    log_deploy "Starting Vercel deployment..."
    
    if ! check_token "VERCEL_TOKEN" "$VERCEL_TOKEN"; then
        log_warning "Skipping Vercel deployment - token not configured"
        return 1
    fi
    
    # Set timeout (default 3 minutes, can be overridden with VERCEL_TIMEOUT env var)
    TIMEOUT=${VERCEL_TIMEOUT:-180}
    log_info "Deployment timeout set to ${TIMEOUT} seconds"
    
    start_time=$(get_timestamp)
    
    # Deploy to Vercel with timeout
    timeout $TIMEOUT vercel --token "$VERCEL_TOKEN" --yes --prod 2>&1 | tee "deployment-$(date +%Y%m%d-%H%M%S).log"
    
    # Check if timeout occurred
    if [ $? -eq 124 ]; then
        end_time=$(get_timestamp)
        deployment_time=$(calculate_duration $start_time $end_time)
        
        log_error "Deployment timed out after ${deployment_time} seconds (${TIMEOUT}s limit)"
        log_metrics "deployment-metrics.log" "Vercel" "$deployment_time" "TIMEOUT"
        
        log_warning "Tips to fix timeout:"
        echo "  - Check your internet connection"
        echo "  - Try again (first deployments are slower)"
        echo "  - Increase timeout: VERCEL_TIMEOUT=900 ./scripts/deploy.sh deploy"
        echo "  - Check Vercel status: https://vercel-status.com"
        
        return 1
    fi
    
    end_time=$(get_timestamp)
    deployment_time=$(calculate_duration $start_time $end_time)
    
    # Log metrics
    log_success "Deployment completed in ${deployment_time} seconds"
    log_metrics "deployment-metrics.log" "Vercel" "$deployment_time" "SUCCESS"
    
    # Performance analysis
    if [ $deployment_time -lt 60 ]; then
        log_success "Fast deployment (< 1 minute)"
    elif [ $deployment_time -lt 180 ]; then
        log_warning "Normal deployment (1-3 minutes)"
    else
        log_error "Slow deployment (> 3 minutes) - check logs"
    fi
    
    return 0
}

# Function to start ngrok tunnel
start_ngrok() {
    log_step "Starting ngrok tunnel..."
    
    if ! check_token "NGROK_AUTHTOKEN" "$NGROK_AUTHTOKEN"; then
        log_warning "Skipping ngrok - token not configured"
        return 1
    fi
    
    # Configure ngrok if not already configured
    if [ ! -f ~/.config/ngrok/ngrok.yml ]; then
        log_step "Configuring ngrok..."
        ngrok config add-authtoken "$NGROK_AUTHTOKEN"
    fi
    
    # Start ngrok tunnel
    log_success "Starting ngrok tunnel on port 3000..."
    ngrok http 3000 &
    NGROK_PID=$!
    
    # Wait a moment for ngrok to start
    sleep 5
    
    # Get the tunnel URL
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])")
        log_success "Ngrok tunnel started: $TUNNEL_URL"
        log_info "Monitor at: http://localhost:4040"
    else
        log_error "Failed to start ngrok tunnel"
        return 1
    fi
    
    return 0
}

# Function to start development server
start_dev() {
    log_step "Starting development server..."
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        log_step "Installing dependencies..."
        pnpm install
    fi
    
    # Start development server
    log_success "Starting development server on http://localhost:3000"
    pnpm dev:next &
    DEV_PID=$!
    
    # Wait for server to start
    sleep 10
    
    # Check if server is running
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        log_success "Development server is running"
        return 0
    else
        log_error "Failed to start development server"
        return 1
    fi
}

# Function to show usage
show_usage() {
    local commands="  dev     - Start development server only
  ngrok   - Start ngrok tunnel only
  tunnel  - Start dev server + ngrok tunnel
  deploy  - Deploy to Vercel production
  all     - Start dev server + ngrok + deploy to Vercel
  status  - Show deployment metrics
  help    - Show this help"
    
    local prerequisites="  Make sure to set VERCEL_TOKEN and NGROK_AUTHTOKEN in .env file"
    
    show_usage "T3 Turbo Deployment Script" "This script handles both development (ngrok) and production (Vercel) deployments" "$commands" "$prerequisites"
}

# Function to show deployment status
show_status() {
    log_info "Deployment Status"
    echo ""
    
    show_recent_metrics "deployment-metrics.log" 10
    echo ""
    
    log_info "Current services:"
    
    # Check if development server is running
    check_port 3000 "Development server"
    
    # Check if ngrok is running
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])" 2>/dev/null || echo "Unknown")
        log_success "Ngrok tunnel: $TUNNEL_URL"
        log_info "Ngrok monitor: http://localhost:4040"
    else
        log_error "Ngrok tunnel: Not running"
    fi
}

# Main script logic
case "${1:-help}" in
    "dev")
        start_dev
        echo -e "${GREEN}🎉 Development server started!${NC}"
        echo -e "${BLUE}Press Ctrl+C to stop${NC}"
        wait $DEV_PID
        ;;
    "ngrok")
        start_ngrok
        echo -e "${GREEN}🎉 Ngrok tunnel started!${NC}"
        echo -e "${BLUE}Press Ctrl+C to stop${NC}"
        wait $NGROK_PID
        ;;
    "tunnel")
        start_dev
        start_ngrok
        echo -e "${GREEN}🎉 Development server and ngrok tunnel started!${NC}"
        echo -e "${BLUE}Press Ctrl+C to stop${NC}"
        wait $DEV_PID $NGROK_PID
        ;;
    "deploy")
        deploy_vercel
        ;;
    "all")
        start_dev
        start_ngrok
        deploy_vercel
        echo -e "${GREEN}🎉 All services started and deployed!${NC}"
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_usage
        ;;
esac