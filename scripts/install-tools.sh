#!/bin/bash

# T3 Turbo Tool Installation Script
# This script checks and installs all required tools for deployment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Node.js if needed
install_node() {
    if ! command_exists node; then
        echo -e "${BLUE}📦 Installing Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
        echo -e "${GREEN}✅ Node.js installed${NC}"
    else
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}✅ Node.js already installed: $NODE_VERSION${NC}"
    fi
}

# Function to install pnpm if needed
install_pnpm() {
    if ! command_exists pnpm; then
        echo -e "${BLUE}📦 Installing pnpm...${NC}"
        npm install -g pnpm
        echo -e "${GREEN}✅ pnpm installed${NC}"
    else
        PNPM_VERSION=$(pnpm --version)
        echo -e "${GREEN}✅ pnpm already installed: $PNPM_VERSION${NC}"
    fi
}

# Function to install Vercel CLI if needed
install_vercel() {
    if ! command_exists vercel; then
        echo -e "${BLUE}📦 Installing Vercel CLI...${NC}"
        npm install -g vercel
        echo -e "${GREEN}✅ Vercel CLI installed${NC}"
    else
        VERCEL_VERSION=$(vercel --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✅ Vercel CLI already installed: $VERCEL_VERSION${NC}"
    fi
}

# Function to install ngrok if needed
install_ngrok() {
    if ! command_exists ngrok; then
        echo -e "${BLUE}📦 Installing ngrok...${NC}"
        npm install -g ngrok
        echo -e "${GREEN}✅ ngrok installed${NC}"
    else
        NGROK_VERSION=$(ngrok version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✅ ngrok already installed: $NGROK_VERSION${NC}"
    fi
}

# Function to install EAS CLI if needed
install_eas() {
    if ! command_exists eas; then
        echo -e "${BLUE}📦 Installing EAS CLI...${NC}"
        npm install -g eas-cli
        echo -e "${GREEN}✅ EAS CLI installed${NC}"
    else
        EAS_VERSION=$(eas --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✅ EAS CLI already installed: $EAS_VERSION${NC}"
    fi
}

# Function to install Python if needed (for ngrok tunnel parsing)
install_python() {
    if ! command_exists python3; then
        echo -e "${BLUE}📦 Installing Python 3...${NC}"
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
        echo -e "${GREEN}✅ Python 3 installed${NC}"
    else
        PYTHON_VERSION=$(python3 --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✅ Python 3 already installed: $PYTHON_VERSION${NC}"
    fi
}

# Function to install curl if needed
install_curl() {
    if ! command_exists curl; then
        echo -e "${BLUE}📦 Installing curl...${NC}"
        sudo apt-get update
        sudo apt-get install -y curl
        echo -e "${GREEN}✅ curl installed${NC}"
    else
        echo -e "${GREEN}✅ curl already installed${NC}"
    fi
}

# Function to check and install all tools
install_all_tools() {
    echo -e "${BLUE}🔧 Installing Required Tools${NC}"
    echo ""
    
    # Check if we're on a supported system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${BLUE}🐧 Linux system detected${NC}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}🍎 macOS system detected${NC}"
        echo -e "${YELLOW}⚠️ For macOS, please install tools manually or use Homebrew${NC}"
        echo "brew install node pnpm"
        echo "npm install -g vercel ngrok eas-cli"
        return
    else
        echo -e "${YELLOW}⚠️ Unsupported system: $OSTYPE${NC}"
        echo "Please install tools manually"
        return
    fi
    
    # Install basic tools first
    install_curl
    install_python
    
    # Install Node.js and npm
    install_node
    
    # Install package managers and CLIs
    install_pnpm
    install_vercel
    install_ngrok
    install_eas
    
    echo ""
    echo -e "${GREEN}🎉 All tools installed successfully!${NC}"
}

# Function to check tool versions
check_versions() {
    echo -e "${BLUE}📊 Tool Versions${NC}"
    echo ""
    
    if command_exists node; then
        echo -e "${GREEN}Node.js: $(node --version)${NC}"
    else
        echo -e "${RED}Node.js: Not installed${NC}"
    fi
    
    if command_exists pnpm; then
        echo -e "${GREEN}pnpm: $(pnpm --version)${NC}"
    else
        echo -e "${RED}pnpm: Not installed${NC}"
    fi
    
    if command_exists vercel; then
        echo -e "${GREEN}Vercel CLI: $(vercel --version 2>/dev/null || echo "unknown")${NC}"
    else
        echo -e "${RED}Vercel CLI: Not installed${NC}"
    fi
    
    if command_exists ngrok; then
        echo -e "${GREEN}ngrok: $(ngrok version 2>/dev/null || echo "unknown")${NC}"
    else
        echo -e "${RED}ngrok: Not installed${NC}"
    fi
    
    if command_exists eas; then
        echo -e "${GREEN}EAS CLI: $(eas --version 2>/dev/null || echo "unknown")${NC}"
    else
        echo -e "${RED}EAS CLI: Not installed${NC}"
    fi
    
    if command_exists python3; then
        echo -e "${GREEN}Python 3: $(python3 --version 2>/dev/null || echo "unknown")${NC}"
    else
        echo -e "${RED}Python 3: Not installed${NC}"
    fi
    
    if command_exists curl; then
        echo -e "${GREEN}curl: Installed${NC}"
    else
        echo -e "${RED}curl: Not installed${NC}"
    fi
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}T3 Turbo Tool Installation Script${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install  - Install all required tools"
    echo "  check    - Check tool versions"
    echo "  node     - Install Node.js only"
    echo "  pnpm     - Install pnpm only"
    echo "  vercel   - Install Vercel CLI only"
    echo "  ngrok    - Install ngrok only"
    echo "  eas      - Install EAS CLI only"
    echo "  help     - Show this help"
    echo ""
    echo "Required tools:"
    echo "  - Node.js (>=22.14.0)"
    echo "  - pnpm (>=9.6.0)"
    echo "  - Vercel CLI"
    echo "  - ngrok"
    echo "  - EAS CLI"
    echo "  - Python 3 (for ngrok tunnel parsing)"
    echo "  - curl"
    echo ""
}

# Main script logic
case "${1:-help}" in
    "install")
        install_all_tools
        ;;
    "check")
        check_versions
        ;;
    "node")
        install_node
        ;;
    "pnpm")
        install_pnpm
        ;;
    "vercel")
        install_vercel
        ;;
    "ngrok")
        install_ngrok
        ;;
    "eas")
        install_eas
        ;;
    "help"|*)
        show_usage
        ;;
esac