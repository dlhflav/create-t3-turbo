#!/bin/bash

# T3 Turbo Complete Deployment Script
# This script handles both web and mobile deployments

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo -e "${BLUE}T3 Turbo Complete Deployment Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  web:dev     - Start web development server"
    echo "  web:deploy  - Deploy web to Vercel"
    echo "  web:tunnel  - Start web dev + ngrok tunnel"
    echo "  mobile:dev  - Start mobile development server"
    echo "  mobile:build - Build mobile app (development)"
    echo "  mobile:prod - Build mobile app (production)"
    echo "  mobile:credentials - Configure mobile build credentials"
    echo "  all:web     - Complete web deployment (dev + tunnel + deploy)"
    echo "  all:mobile  - Complete mobile deployment (dev + build)"
    echo "  status      - Show all services status"
    echo "  help        - Show this help"
    echo ""
    echo "Prerequisites:"
    echo "  - Vercel account & token: https://vercel.com/account/tokens"
    echo "  - Ngrok account & token: https://ngrok.com/dashboard/your/authtokens"
    echo "  - Expo account & token: https://expo.dev/accounts/[username]/settings/access-tokens"
    echo "  - Set tokens in Cursor Secrets or .env file"
    echo ""
}

# Function to deploy web
deploy_web() {
    echo -e "${BLUE}🌐 Deploying Web App...${NC}"
    ./scripts/deploy.sh deploy
}

# Function to start web development
start_web_dev() {
    echo -e "${BLUE}🌐 Starting Web Development...${NC}"
    ./scripts/deploy.sh dev
}

# Function to start web tunnel
start_web_tunnel() {
    echo -e "${BLUE}🌐 Starting Web Tunnel...${NC}"
    ./scripts/deploy.sh tunnel
}

# Function to deploy mobile
deploy_mobile() {
    echo -e "${BLUE}📱 Building Mobile App...${NC}"
    ./scripts/mobile-deploy.sh build:dev
}

# Function to deploy mobile production
deploy_mobile_prod() {
    echo -e "${BLUE}📱 Building Mobile App (Production)...${NC}"
    ./scripts/mobile-deploy.sh build:prod
}

# Function to start mobile development
start_mobile_dev() {
    echo -e "${BLUE}📱 Starting Mobile Development...${NC}"
    ./scripts/mobile-deploy.sh dev
}

# Function to configure mobile credentials
configure_mobile_credentials() {
    echo -e "${BLUE}🔐 Configuring Mobile Build Credentials...${NC}"
    ./scripts/mobile-deploy.sh credentials
}

# Function to show complete status
show_status() {
    echo -e "${BLUE}📊 Complete Deployment Status${NC}"
    echo ""
    
    echo -e "${GREEN}🌐 Web Status:${NC}"
    ./scripts/deploy.sh status
    echo ""
    
    echo -e "${GREEN}📱 Mobile Status:${NC}"
    ./scripts/mobile-deploy.sh status 2>/dev/null || echo "Mobile status check failed"
    echo ""
    
    echo -e "${BLUE}📈 Combined Metrics:${NC}"
    if [ -f "deployment-metrics.log" ] && [ -f "mobile-build-metrics.log" ]; then
        echo "Recent Web Deployments:"
        tail -3 deployment-metrics.log
        echo ""
        echo "Recent Mobile Builds:"
        tail -3 mobile-build-metrics.log
    elif [ -f "deployment-metrics.log" ]; then
        echo "Recent Web Deployments:"
        tail -5 deployment-metrics.log
    elif [ -f "mobile-build-metrics.log" ]; then
        echo "Recent Mobile Builds:"
        tail -5 mobile-build-metrics.log
    else
        echo -e "${YELLOW}No deployment metrics found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔧 System Health Check:${NC}"
    
    # Check if all required tools are installed
    if command -v vercel &> /dev/null; then
        echo -e "${GREEN}✅ Vercel CLI: Installed${NC}"
    else
        echo -e "${RED}❌ Vercel CLI: Not installed${NC}"
    fi
    
    if command -v ngrok &> /dev/null; then
        echo -e "${GREEN}✅ Ngrok CLI: Installed${NC}"
    else
        echo -e "${RED}❌ Ngrok CLI: Not installed${NC}"
    fi
    
    if command -v eas &> /dev/null; then
        echo -e "${GREEN}✅ EAS CLI: Installed${NC}"
    else
        echo -e "${RED}❌ EAS CLI: Not installed${NC}"
    fi
    
    if command -v pnpm &> /dev/null; then
        echo -e "${GREEN}✅ pnpm: Installed${NC}"
    else
        echo -e "${RED}❌ pnpm: Not installed${NC}"
    fi
}

# Function to deploy all web services
deploy_all_web() {
    echo -e "${BLUE}🚀 Complete Web Deployment${NC}"
    echo ""
    
    # Start development server in background
    echo -e "${BLUE}1️⃣ Starting development server...${NC}"
    ./scripts/deploy.sh dev &
    DEV_PID=$!
    
    # Wait a bit for server to start
    sleep 5
    
    # Start ngrok tunnel in background
    echo -e "${BLUE}2️⃣ Starting ngrok tunnel...${NC}"
    ./scripts/deploy.sh ngrok &
    NGROK_PID=$!
    
    # Wait a bit for tunnel to establish
    sleep 10
    
    # Deploy to Vercel
    echo -e "${BLUE}3️⃣ Deploying to Vercel...${NC}"
    ./scripts/deploy.sh deploy
    
    # Show status
    echo -e "${BLUE}4️⃣ Final Status:${NC}"
    show_status
    
    # Cleanup background processes
    kill $DEV_PID $NGROK_PID 2>/dev/null || true
}

# Function to deploy all mobile services
deploy_all_mobile() {
    echo -e "${BLUE}🚀 Complete Mobile Deployment${NC}"
    echo ""
    
    # Start development server in background
    echo -e "${BLUE}1️⃣ Starting mobile development server...${NC}"
    ./scripts/mobile-deploy.sh dev &
    MOBILE_PID=$!
    
    # Wait a bit for server to start
    sleep 5
    
    # Build mobile app
    echo -e "${BLUE}2️⃣ Building mobile app...${NC}"
    ./scripts/mobile-deploy.sh build:dev
    
    # Show status
    echo -e "${BLUE}3️⃣ Final Status:${NC}"
    show_status
    
    # Cleanup background processes
    kill $MOBILE_PID 2>/dev/null || true
}

# Function to install missing tools
install_tools() {
    echo -e "${BLUE}🔧 Installing Required Tools${NC}"
    echo ""
    
    # Install Vercel CLI if not present
    if ! command -v vercel &> /dev/null; then
        echo -e "${BLUE}📦 Installing Vercel CLI...${NC}"
        npm install -g vercel
    fi
    
    # Install ngrok if not present
    if ! command -v ngrok &> /dev/null; then
        echo -e "${BLUE}📦 Installing ngrok...${NC}"
        npm install -g ngrok
    fi
    
    # Install EAS CLI if not present
    if ! command -v eas &> /dev/null; then
        echo -e "${BLUE}📦 Installing EAS CLI...${NC}"
        npm install -g eas-cli
    fi
    
    # Install pnpm if not present
    if ! command -v pnpm &> /dev/null; then
        echo -e "${BLUE}📦 Installing pnpm...${NC}"
        npm install -g pnpm
    fi
    
    echo -e "${GREEN}✅ All tools installed${NC}"
}

# Main script logic
case "${1:-help}" in
    "web:dev")
        start_web_dev
        ;;
    "web:deploy")
        deploy_web
        ;;
    "web:tunnel")
        start_web_tunnel
        ;;
    "mobile:dev")
        start_mobile_dev
        ;;
    "mobile:build")
        deploy_mobile
        ;;
    "mobile:prod")
        deploy_mobile_prod
        ;;
    "mobile:credentials")
        configure_mobile_credentials
        ;;
    "all:web")
        deploy_all_web
        ;;
    "all:mobile")
        deploy_all_mobile
        ;;
    "install")
        install_tools
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_usage
        ;;
esac