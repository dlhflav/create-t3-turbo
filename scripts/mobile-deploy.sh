#!/bin/bash

# T3 Turbo Mobile Deployment Script
# This script handles Expo mobile app builds and deployments

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
    echo -e "${YELLOW}⚠️ .env file not found, using environment variables${NC}"
fi

# Function to check if EAS CLI is installed
check_eas() {
    if ! command -v eas &> /dev/null; then
        echo -e "${RED}❌ EAS CLI not installed. Installing...${NC}"
        npm install -g eas-cli
    fi
    echo -e "${GREEN}✅ EAS CLI found${NC}"
}

# Function to check if logged in to Expo
check_expo_login() {
    if ! eas whoami &> /dev/null; then
        echo -e "${YELLOW}⚠️ Not logged in to Expo${NC}"
        echo -e "${BLUE}📋 Authentication Options:${NC}"
        echo "1. Interactive login: eas login"
        echo "2. Use access token: EXPO_TOKEN=your_token"
        echo "3. Get token from: https://expo.dev/accounts/[username]/settings/access-tokens"
        echo ""
        echo -e "${YELLOW}💡 For automated deployments, create an access token and set EXPO_TOKEN${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Logged in to Expo${NC}"
    return 0
}

# Function to build for development
build_dev() {
    echo -e "${BLUE}🔧 Building development build...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    start_time=$(date +%s)
    
    cd apps/expo
    
    # Build for development
    eas build --profile development --platform all --non-interactive
    
    end_time=$(date +%s)
    build_time=$((end_time - start_time))
    
    echo -e "${GREEN}📊 Development build completed in ${build_time} seconds${NC}"
    echo "Date: $(date)" >> ../../mobile-build-metrics.log
    echo "Type: Development" >> ../../mobile-build-metrics.log
    echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
    echo "Status: SUCCESS" >> ../../mobile-build-metrics.log
    echo "---" >> ../../mobile-build-metrics.log
    
    cd ../..
}

# Function to build for preview
build_preview() {
    echo -e "${BLUE}🔧 Building preview build...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    start_time=$(date +%s)
    
    cd apps/expo
    
    # Build for preview
    eas build --profile preview --platform all --non-interactive
    
    end_time=$(date +%s)
    build_time=$((end_time - start_time))
    
    echo -e "${GREEN}📊 Preview build completed in ${build_time} seconds${NC}"
    echo "Date: $(date)" >> ../../mobile-build-metrics.log
    echo "Type: Preview" >> ../../mobile-build-metrics.log
    echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
    echo "Status: SUCCESS" >> ../../mobile-build-metrics.log
    echo "---" >> ../../mobile-build-metrics.log
    
    cd ../..
}

# Function to build for production
build_production() {
    echo -e "${BLUE}🚀 Building production build...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    start_time=$(date +%s)
    
    cd apps/expo
    
    # Build for production
    eas build --profile production --platform all --non-interactive
    
    end_time=$(date +%s)
    build_time=$((end_time - start_time))
    
    echo -e "${GREEN}📊 Production build completed in ${build_time} seconds${NC}"
    echo "Date: $(date)" >> ../../mobile-build-metrics.log
    echo "Type: Production" >> ../../mobile-build-metrics.log
    echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
    echo "Status: SUCCESS" >> ../../mobile-build-metrics.log
    echo "---" >> ../../mobile-build-metrics.log
    
    cd ../..
}

# Function to submit to app stores
submit_apps() {
    echo -e "${BLUE}📱 Submitting to app stores...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    cd apps/expo
    
    # Submit to iOS App Store
    echo -e "${BLUE}🍎 Submitting to iOS App Store...${NC}"
    eas submit --platform ios --latest
    
    # Submit to Google Play Store
    echo -e "${BLUE}🤖 Submitting to Google Play Store...${NC}"
    eas submit --platform android --latest
    
    cd ../..
    
    echo -e "${GREEN}✅ App store submissions completed${NC}"
}

# Function to start development server
start_dev() {
    echo -e "${BLUE}🔧 Starting Expo development server...${NC}"
    
    cd apps/expo
    
    # Start development server
    pnpm dev
    
    cd ../..
}

# Function to show build status
show_status() {
    echo -e "${BLUE}📊 Mobile Build Status${NC}"
    echo ""
    
    if [ -f "mobile-build-metrics.log" ]; then
        echo -e "${GREEN}Recent builds:${NC}"
        tail -10 mobile-build-metrics.log
        echo ""
        
        # Calculate average build time
        if [ -s "mobile-build-metrics.log" ]; then
            AVG_TIME=$(grep "Duration:" mobile-build-metrics.log | awk '{sum+=$2} END {print sum/NR}')
            echo -e "${BLUE}Average build time: ${AVG_TIME} seconds${NC}"
        fi
    else
        echo -e "${YELLOW}No build metrics found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Current services:${NC}"
    
    # Check if Expo dev server is running
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Expo dev server: http://localhost:8081${NC}"
    else
        echo -e "${RED}❌ Expo dev server: Not running${NC}"
    fi
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}T3 Turbo Mobile Deployment Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  dev        - Start Expo development server"
    echo "  build:dev  - Build development version"
    echo "  build:preview - Build preview version"
    echo "  build:prod - Build production version"
    echo "  submit     - Submit to app stores"
    echo "  status     - Show build metrics"
    echo "  help       - Show this help"
    echo ""
    echo "Prerequisites:"
    echo "  - Expo account: https://expo.dev"
    echo "  - EAS CLI: npm install -g eas-cli"
    echo "  - Login: eas login"
    echo ""
}

# Main script logic
case "${1:-help}" in
    "dev")
        start_dev
        ;;
    "build:dev")
        check_eas
        build_dev
        ;;
    "build:preview")
        check_eas
        build_preview
        ;;
    "build:prod")
        check_eas
        build_production
        ;;
    "submit")
        check_eas
        submit_apps
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_usage
        ;;
esac