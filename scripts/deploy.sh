#!/bin/bash

# T3 Turbo Deployment Script
# This script handles both development (ngrok) and production (Vercel) deployments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    echo -e "${BLUE}📋 Loading environment variables...${NC}"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}❌ .env file not found! Please create one from .env.example${NC}"
    exit 1
fi

# Function to check if token is set
check_token() {
    local token_name=$1
    local token_value=$2
    
    if [ -z "$token_value" ] || [ "$token_value" = "your-$token_name-here" ]; then
        echo -e "${RED}❌ $token_name not set in .env file${NC}"
        return 1
    fi
    return 0
}

# Function to deploy to Vercel
deploy_vercel() {
    echo -e "${BLUE}🚀 Starting Vercel deployment...${NC}"
    
    if ! check_token "VERCEL_TOKEN" "$VERCEL_TOKEN"; then
        echo -e "${YELLOW}⚠️ Skipping Vercel deployment - token not configured${NC}"
        return 1
    fi
    
    # Set timeout (default 3 minutes, can be overridden with VERCEL_TIMEOUT env var)
    TIMEOUT=${VERCEL_TIMEOUT:-180}
    echo -e "${BLUE}⏱️ Deployment timeout set to ${TIMEOUT} seconds${NC}"
    
    start_time=$(date +%s)
    
    # Deploy to Vercel with timeout
    timeout $TIMEOUT vercel --token "$VERCEL_TOKEN" --yes --prod 2>&1 | tee "deployment-$(date +%Y%m%d-%H%M%S).log"
    
    # Check if timeout occurred
    if [ $? -eq 124 ]; then
        end_time=$(date +%s)
        deployment_time=$((end_time - start_time))
        
        echo -e "${RED}⏰ Deployment timed out after ${deployment_time} seconds (${TIMEOUT}s limit)${NC}"
        echo "Date: $(date)" >> deployment-metrics.log
        echo "Duration: ${deployment_time} seconds (TIMEOUT)" >> deployment-metrics.log
        echo "Status: TIMEOUT" >> deployment-metrics.log
        echo "---" >> deployment-metrics.log
        
        echo -e "${YELLOW}💡 Tips to fix timeout:${NC}"
        echo -e "  - Check your internet connection"
        echo -e "  - Try again (first deployments are slower)"
        echo -e "  - Increase timeout: VERCEL_TIMEOUT=900 ./scripts/deploy.sh deploy"
        echo -e "  - Check Vercel status: https://vercel-status.com"
        
        return 1
    fi
    
    end_time=$(date +%s)
    deployment_time=$((end_time - start_time))
    
    # Log metrics
    echo -e "${GREEN}📊 Deployment completed in ${deployment_time} seconds${NC}"
    echo "Date: $(date)" >> deployment-metrics.log
    echo "Duration: ${deployment_time} seconds" >> deployment-metrics.log
    echo "Status: SUCCESS" >> deployment-metrics.log
    echo "---" >> deployment-metrics.log
    
    # Performance analysis
    if [ $deployment_time -lt 60 ]; then
        echo -e "${GREEN}✅ Fast deployment (< 1 minute)${NC}"
    elif [ $deployment_time -lt 180 ]; then
        echo -e "${YELLOW}⚠️ Normal deployment (1-3 minutes)${NC}"
    else
        echo -e "${RED}🐌 Slow deployment (> 3 minutes) - check logs${NC}"
    fi
    
    return 0
}

# Function to start ngrok tunnel
start_ngrok() {
    echo -e "${BLUE}🌐 Starting ngrok tunnel...${NC}"
    
    if ! check_token "NGROK_AUTHTOKEN" "$NGROK_AUTHTOKEN"; then
        echo -e "${YELLOW}⚠️ Skipping ngrok - token not configured${NC}"
        return 1
    fi
    
    # Configure ngrok if not already configured
    if [ ! -f ~/.config/ngrok/ngrok.yml ]; then
        echo -e "${BLUE}🔧 Configuring ngrok...${NC}"
        ngrok config add-authtoken "$NGROK_AUTHTOKEN"
    fi
    
    # Start ngrok tunnel
    echo -e "${GREEN}✅ Starting ngrok tunnel on port 3000...${NC}"
    ngrok http 3000 &
    NGROK_PID=$!
    
    # Wait a moment for ngrok to start
    sleep 5
    
    # Get the tunnel URL
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])")
        echo -e "${GREEN}✅ Ngrok tunnel started: $TUNNEL_URL${NC}"
        echo -e "${BLUE}📊 Monitor at: http://localhost:4040${NC}"
    else
        echo -e "${RED}❌ Failed to start ngrok tunnel${NC}"
        return 1
    fi
    
    return 0
}

# Function to start development server
start_dev() {
    echo -e "${BLUE}🔧 Starting development server...${NC}"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo -e "${BLUE}📦 Installing dependencies...${NC}"
        pnpm install
    fi
    
    # Start development server
    echo -e "${GREEN}✅ Starting development server on http://localhost:3000${NC}"
    pnpm dev:next &
    DEV_PID=$!
    
    # Wait for server to start
    sleep 10
    
    # Check if server is running
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Development server is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start development server${NC}"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}T3 Turbo Deployment Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  dev     - Start development server only"
    echo "  ngrok   - Start ngrok tunnel only"
    echo "  tunnel  - Start dev server + ngrok tunnel"
    echo "  deploy  - Deploy to Vercel production"
    echo "  all     - Start dev server + ngrok + deploy to Vercel"
    echo "  status  - Show deployment metrics"
    echo "  help    - Show this help"
    echo ""
    echo "Environment:"
    echo "  Make sure to set VERCEL_TOKEN and NGROK_AUTHTOKEN in .env file"
    echo ""
}

# Function to show deployment status
show_status() {
    echo -e "${BLUE}📊 Deployment Status${NC}"
    echo ""
    
    if [ -f "deployment-metrics.log" ]; then
        echo -e "${GREEN}Recent deployments:${NC}"
        tail -10 deployment-metrics.log
        echo ""
        
        # Calculate average deployment time
        if [ -s "deployment-metrics.log" ]; then
            AVG_TIME=$(grep "Duration:" deployment-metrics.log | awk '{sum+=$2} END {print sum/NR}')
            echo -e "${BLUE}Average deployment time: ${AVG_TIME} seconds${NC}"
        fi
    else
        echo -e "${YELLOW}No deployment metrics found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Current services:${NC}"
    
    # Check if development server is running
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Development server: http://localhost:3000${NC}"
    else
        echo -e "${RED}❌ Development server: Not running${NC}"
    fi
    
    # Check if ngrok is running
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])" 2>/dev/null || echo "Unknown")
        echo -e "${GREEN}✅ Ngrok tunnel: $TUNNEL_URL${NC}"
        echo -e "${BLUE}📊 Ngrok monitor: http://localhost:4040${NC}"
    else
        echo -e "${RED}❌ Ngrok tunnel: Not running${NC}"
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