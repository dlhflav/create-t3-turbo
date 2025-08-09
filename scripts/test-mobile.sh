#!/bin/bash

# T3 Turbo Mobile Deployment Test Script
# This script tests all mobile deployment functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Mobile Deployment Scripts${NC}"
echo ""

# Test 1: Check if mobile deployment script exists
echo -e "${BLUE}1️⃣ Testing script existence...${NC}"
if [ -f "scripts/mobile-deploy.sh" ]; then
    echo -e "${GREEN}✅ Mobile deployment script found${NC}"
else
    echo -e "${RED}❌ Mobile deployment script not found${NC}"
    exit 1
fi

# Test 2: Check if script is executable
echo -e "${BLUE}2️⃣ Testing script permissions...${NC}"
if [ -x "scripts/mobile-deploy.sh" ]; then
    echo -e "${GREEN}✅ Script is executable${NC}"
else
    echo -e "${YELLOW}⚠️ Making script executable...${NC}"
    chmod +x scripts/mobile-deploy.sh
    echo -e "${GREEN}✅ Script is now executable${NC}"
fi

# Test 3: Test help command
echo -e "${BLUE}3️⃣ Testing help command...${NC}"
if ./scripts/mobile-deploy.sh help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Help command works${NC}"
else
    echo -e "${RED}❌ Help command failed${NC}"
fi

# Test 4: Test status command
echo -e "${BLUE}4️⃣ Testing status command...${NC}"
if ./scripts/mobile-deploy.sh status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Status command works${NC}"
else
    echo -e "${RED}❌ Status command failed${NC}"
fi

# Test 5: Check EAS CLI
echo -e "${BLUE}5️⃣ Testing EAS CLI...${NC}"
if command -v eas &> /dev/null; then
    echo -e "${GREEN}✅ EAS CLI is installed${NC}"
    echo -e "${BLUE}   Version: $(eas --version)${NC}"
else
    echo -e "${RED}❌ EAS CLI is not installed${NC}"
fi

# Test 6: Check Expo login
echo -e "${BLUE}6️⃣ Testing Expo login...${NC}"
if eas whoami &> /dev/null 2>&1; then
    echo -e "${GREEN}✅ Logged in to Expo${NC}"
else
    echo -e "${YELLOW}⚠️ Not logged in to Expo${NC}"
fi

# Test 7: Check project configuration
echo -e "${BLUE}7️⃣ Testing project configuration...${NC}"
if [ -f "apps/expo/eas.json" ]; then
    echo -e "${GREEN}✅ EAS configuration found${NC}"
else
    echo -e "${RED}❌ EAS configuration not found${NC}"
fi

if [ -f "apps/expo/app.config.ts" ]; then
    echo -e "${GREEN}✅ App configuration found${NC}"
else
    echo -e "${RED}❌ App configuration not found${NC}"
fi

# Test 8: Check dependencies
echo -e "${BLUE}8️⃣ Testing dependencies...${NC}"
if [ -d "apps/expo/node_modules" ]; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️ Dependencies not installed${NC}"
fi

# Test 9: Test development server (non-blocking)
echo -e "${BLUE}9️⃣ Testing development server...${NC}"
if curl -s http://localhost:8081 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Development server is running${NC}"
else
    echo -e "${YELLOW}⚠️ Development server is not running${NC}"
    echo -e "${BLUE}   You can start it with: ./scripts/mobile-deploy.sh dev${NC}"
fi

# Test 10: Check deploy-all script integration
echo -e "${BLUE}🔟 Testing deploy-all integration...${NC}"
if [ -f "scripts/deploy-all.sh" ]; then
    echo -e "${GREEN}✅ Deploy-all script found${NC}"
    if ./scripts/deploy-all.sh help > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Deploy-all script works${NC}"
    else
        echo -e "${RED}❌ Deploy-all script failed${NC}"
    fi
else
    echo -e "${RED}❌ Deploy-all script not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Mobile deployment test completed!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Start development server: ./scripts/mobile-deploy.sh dev"
echo "2. Configure credentials: ./scripts/mobile-deploy.sh credentials"
echo "3. Build app: ./scripts/mobile-deploy.sh build:dev"
echo "4. Check status: ./scripts/mobile-deploy.sh status"
echo ""
echo -e "${BLUE}📚 Available commands:${NC}"
./scripts/mobile-deploy.sh help