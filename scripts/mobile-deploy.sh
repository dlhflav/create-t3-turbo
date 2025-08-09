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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check and install required tools
check_and_install_tools() {
    echo -e "${BLUE}🔧 Checking required tools...${NC}"
    
    # Check and install EAS CLI
    if ! command_exists eas; then
        echo -e "${BLUE}📦 Installing EAS CLI...${NC}"
        npm install -g eas-cli
        echo -e "${GREEN}✅ EAS CLI installed${NC}"
    else
        echo -e "${GREEN}✅ EAS CLI found${NC}"
    fi
    
    # Check and install pnpm if needed
    if ! command_exists pnpm; then
        echo -e "${BLUE}📦 Installing pnpm...${NC}"
        npm install -g pnpm
        echo -e "${GREEN}✅ pnpm installed${NC}"
    else
        echo -e "${GREEN}✅ pnpm found${NC}"
    fi
    
    # Check and install Python if needed (for ngrok tunnel parsing)
    if ! command_exists python3; then
        echo -e "${BLUE}📦 Installing Python 3...${NC}"
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip
        else
            echo -e "${YELLOW}⚠️ Please install Python 3 manually${NC}"
        fi
        echo -e "${GREEN}✅ Python 3 installed${NC}"
    else
        echo -e "${GREEN}✅ Python 3 found${NC}"
    fi
}

# Function to check if EAS CLI is installed (legacy function for compatibility)
check_eas() {
    check_and_install_tools
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

# Function to check project configuration
check_project_config() {
    echo -e "${BLUE}🔍 Checking project configuration...${NC}"
    
    if [ ! -f "apps/expo/eas.json" ]; then
        echo -e "${RED}❌ EAS configuration not found${NC}"
        return 1
    fi
    
    if [ ! -f "apps/expo/app.config.ts" ]; then
        echo -e "${RED}❌ App configuration not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Project configuration looks good${NC}"
    return 0
}

# Function to build for development
build_dev() {
    echo -e "${BLUE}🔧 Building development build...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    if ! check_project_config; then
        return 1
    fi
    
    start_time=$(date +%s)
    
    cd apps/expo
    
    echo -e "${YELLOW}⚠️ Note: Mobile builds require app store credentials for iOS/Android${NC}"
    echo -e "${BLUE}📋 Build Options:${NC}"
    echo "1. Development build (requires credentials)"
    echo "2. Preview build (requires credentials)"
    echo "3. Start development server (no credentials needed)"
    echo ""
    echo -e "${YELLOW}💡 For testing without credentials, use: ./scripts/mobile-deploy.sh dev${NC}"
    echo -e "${YELLOW}💡 For builds, configure credentials first: eas credentials:configure-build${NC}"
    
    # Try to build but expect it might fail due to credentials
    if eas build --profile development --platform all --non-interactive; then
        end_time=$(date +%s)
        build_time=$((end_time - start_time))
        
        echo -e "${GREEN}📊 Development build completed in ${build_time} seconds${NC}"
        echo "Date: $(date)" >> ../../mobile-build-metrics.log
        echo "Type: Development" >> ../../mobile-build-metrics.log
        echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
        echo "Status: SUCCESS" >> ../../mobile-build-metrics.log
        echo "---" >> ../../mobile-build-metrics.log
    else
        end_time=$(date +%s)
        build_time=$((end_time - start_time))
        
        echo -e "${RED}❌ Development build failed in ${build_time} seconds${NC}"
        echo "Date: $(date)" >> ../../mobile-build-metrics.log
        echo "Type: Development" >> ../../mobile-build-metrics.log
        echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
        echo "Status: FAILED (credentials required)" >> ../../mobile-build-metrics.log
        echo "---" >> ../../mobile-build-metrics.log
        
        echo -e "${YELLOW}💡 To configure credentials:${NC}"
        echo "1. Run: eas credentials:configure-build --platform android"
        echo "2. Run: eas credentials:configure-build --platform ios"
        echo "3. Or use development server: ./scripts/mobile-deploy.sh dev"
    fi
    
    cd ../..
}

# Function to build for preview
build_preview() {
    echo -e "${BLUE}🔧 Building preview build...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    if ! check_project_config; then
        return 1
    fi
    
    start_time=$(date +%s)
    
    cd apps/expo
    
    # Build for preview
    if eas build --profile preview --platform all --non-interactive; then
        end_time=$(date +%s)
        build_time=$((end_time - start_time))
        
        echo -e "${GREEN}📊 Preview build completed in ${build_time} seconds${NC}"
        echo "Date: $(date)" >> ../../mobile-build-metrics.log
        echo "Type: Preview" >> ../../mobile-build-metrics.log
        echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
        echo "Status: SUCCESS" >> ../../mobile-build-metrics.log
        echo "---" >> ../../mobile-build-metrics.log
    else
        end_time=$(date +%s)
        build_time=$((end_time - start_time))
        
        echo -e "${RED}❌ Preview build failed in ${build_time} seconds${NC}"
        echo "Date: $(date)" >> ../../mobile-build-metrics.log
        echo "Type: Preview" >> ../../mobile-build-metrics.log
        echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
        echo "Status: FAILED" >> ../../mobile-build-metrics.log
        echo "---" >> ../../mobile-build-metrics.log
    fi
    
    cd ../..
}

# Function to build for production
build_production() {
    echo -e "${BLUE}🚀 Building production build...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    if ! check_project_config; then
        return 1
    fi
    
    start_time=$(date +%s)
    
    cd apps/expo
    
    # Build for production
    if eas build --profile production --platform all --non-interactive; then
        end_time=$(date +%s)
        build_time=$((end_time - start_time))
        
        echo -e "${GREEN}📊 Production build completed in ${build_time} seconds${NC}"
        echo "Date: $(date)" >> ../../mobile-build-metrics.log
        echo "Type: Production" >> ../../mobile-build-metrics.log
        echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
        echo "Status: SUCCESS" >> ../../mobile-build-metrics.log
        echo "---" >> ../../mobile-build-metrics.log
    else
        end_time=$(date +%s)
        build_time=$((end_time - start_time))
        
        echo -e "${RED}❌ Production build failed in ${build_time} seconds${NC}"
        echo "Date: $(date)" >> ../../mobile-build-metrics.log
        echo "Type: Production" >> ../../mobile-build-metrics.log
        echo "Duration: ${build_time} seconds" >> ../../mobile-build-metrics.log
        echo "Status: FAILED" >> ../../mobile-build-metrics.log
        echo "---" >> ../../mobile-build-metrics.log
    fi
    
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
    if eas submit --platform ios --latest; then
        echo -e "${GREEN}✅ iOS submission successful${NC}"
    else
        echo -e "${RED}❌ iOS submission failed${NC}"
    fi
    
    # Submit to Google Play Store
    echo -e "${BLUE}🤖 Submitting to Google Play Store...${NC}"
    if eas submit --platform android --latest; then
        echo -e "${GREEN}✅ Android submission successful${NC}"
    else
        echo -e "${RED}❌ Android submission failed${NC}"
    fi
    
    cd ../..
    
    echo -e "${GREEN}✅ App store submissions completed${NC}"
}

# Function to start development server
start_dev() {
    echo -e "${BLUE}🔧 Starting Expo development server...${NC}"
    
    # Check if dependencies are installed
    if [ ! -d "apps/expo/node_modules" ]; then
        echo -e "${BLUE}📦 Installing dependencies...${NC}"
        cd apps/expo && pnpm install && cd ../..
    fi
    
    cd apps/expo
    
    echo -e "${GREEN}🚀 Starting development server on http://localhost:8081${NC}"
    echo -e "${BLUE}📱 You can scan the QR code with Expo Go app${NC}"
    echo -e "${BLUE}💻 Or press 'w' to open in web browser${NC}"
    
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
    
    # Check EAS CLI
    if command -v eas &> /dev/null; then
        echo -e "${GREEN}✅ EAS CLI: Installed${NC}"
    else
        echo -e "${RED}❌ EAS CLI: Not installed${NC}"
    fi
    
    # Check Expo login status
    if eas whoami &> /dev/null 2>&1; then
        echo -e "${GREEN}✅ Expo login: Authenticated${NC}"
    else
        echo -e "${RED}❌ Expo login: Not authenticated${NC}"
    fi
}

# Function to configure credentials
configure_credentials() {
    echo -e "${BLUE}🔐 Configuring build credentials...${NC}"
    
    if ! check_expo_login; then
        return 1
    fi
    
    cd apps/expo
    
    echo -e "${BLUE}📋 Credential Configuration Options:${NC}"
    echo "1. Android credentials"
    echo "2. iOS credentials"
    echo "3. Both platforms"
    echo ""
    
    read -p "Select option (1-3): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}🤖 Configuring Android credentials...${NC}"
            eas credentials:configure-build --platform android
            ;;
        2)
            echo -e "${BLUE}🍎 Configuring iOS credentials...${NC}"
            eas credentials:configure-build --platform ios
            ;;
        3)
            echo -e "${BLUE}🔧 Configuring both platforms...${NC}"
            eas credentials:configure-build --platform android
            eas credentials:configure-build --platform ios
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            return 1
            ;;
    esac
    
    cd ../..
    echo -e "${GREEN}✅ Credential configuration completed${NC}"
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
    echo "  credentials - Configure build credentials"
    echo "  status     - Show build metrics"
    echo "  help       - Show this help"
    echo ""
    echo "Prerequisites:"
    echo "  - Expo account: https://expo.dev"
    echo "  - EAS CLI: npm install -g eas-cli"
    echo "  - Login: eas login"
    echo "  - For builds: Configure credentials with 'credentials' command"
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
    "credentials")
        check_eas
        configure_credentials
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_usage
        ;;
esac