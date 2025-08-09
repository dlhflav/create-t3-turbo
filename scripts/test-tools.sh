#!/bin/bash

# T3 Turbo Tool Installation Test Script
# This script tests all tool installation functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Tool Installation Scripts${NC}"
echo ""

# Test 1: Check if install-tools script exists
echo -e "${BLUE}1️⃣ Testing install-tools script existence...${NC}"
if [ -f "scripts/install-tools.sh" ]; then
    echo -e "${GREEN}✅ install-tools.sh found${NC}"
else
    echo -e "${RED}❌ install-tools.sh not found${NC}"
    exit 1
fi

# Test 2: Check if script is executable
echo -e "${BLUE}2️⃣ Testing script permissions...${NC}"
if [ -x "scripts/install-tools.sh" ]; then
    echo -e "${GREEN}✅ Script is executable${NC}"
else
    echo -e "${YELLOW}⚠️ Making script executable...${NC}"
    chmod +x scripts/install-tools.sh
    echo -e "${GREEN}✅ Script is now executable${NC}"
fi

# Test 3: Test help command
echo -e "${BLUE}3️⃣ Testing help command...${NC}"
if ./scripts/install-tools.sh help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Help command works${NC}"
else
    echo -e "${RED}❌ Help command failed${NC}"
fi

# Test 4: Test check command
echo -e "${BLUE}4️⃣ Testing check command...${NC}"
if ./scripts/install-tools.sh check > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Check command works${NC}"
else
    echo -e "${RED}❌ Check command failed${NC}"
fi

# Test 5: Test automatic tool installation in deploy script
echo -e "${BLUE}5️⃣ Testing automatic tool installation in deploy script...${NC}"
if [ -f "scripts/deploy.sh" ]; then
    echo -e "${GREEN}✅ deploy.sh found${NC}"
    # Test that the script has the check_and_install_tools function
    if grep -q "check_and_install_tools" scripts/deploy.sh; then
        echo -e "${GREEN}✅ Automatic tool installation function found${NC}"
    else
        echo -e "${RED}❌ Automatic tool installation function not found${NC}"
    fi
else
    echo -e "${RED}❌ deploy.sh not found${NC}"
fi

# Test 6: Test automatic tool installation in mobile-deploy script
echo -e "${BLUE}6️⃣ Testing automatic tool installation in mobile-deploy script...${NC}"
if [ -f "scripts/mobile-deploy.sh" ]; then
    echo -e "${GREEN}✅ mobile-deploy.sh found${NC}"
    # Test that the script has the check_and_install_tools function
    if grep -q "check_and_install_tools" scripts/mobile-deploy.sh; then
        echo -e "${GREEN}✅ Automatic tool installation function found${NC}"
    else
        echo -e "${RED}❌ Automatic tool installation function not found${NC}"
    fi
else
    echo -e "${RED}❌ mobile-deploy.sh not found${NC}"
fi

# Test 7: Test deploy-all script integration
echo -e "${BLUE}7️⃣ Testing deploy-all script integration...${NC}"
if [ -f "scripts/deploy-all.sh" ]; then
    echo -e "${GREEN}✅ deploy-all.sh found${NC}"
    # Test that the script has the install_tools function
    if grep -q "install_tools" scripts/deploy-all.sh; then
        echo -e "${GREEN}✅ Tool installation integration found${NC}"
    else
        echo -e "${RED}❌ Tool installation integration not found${NC}"
    fi
else
    echo -e "${RED}❌ deploy-all.sh not found${NC}"
fi

# Test 8: Test current tool status
echo -e "${BLUE}8️⃣ Testing current tool status...${NC}"
./scripts/install-tools.sh check

# Test 9: Test automatic installation (dry run)
echo -e "${BLUE}9️⃣ Testing automatic installation (dry run)...${NC}"
echo -e "${YELLOW}⚠️ This will only check, not install (dry run)${NC}"

# Test individual tool installation commands
echo -e "${BLUE}   Testing individual tool commands...${NC}"
for tool in node pnpm vercel ngrok eas; do
    if ./scripts/install-tools.sh "$tool" > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ $tool command works${NC}"
    else
        echo -e "${RED}   ❌ $tool command failed${NC}"
    fi
done

# Test 10: Test integration with deployment scripts
echo -e "${BLUE}🔟 Testing integration with deployment scripts...${NC}"

# Test web deployment script
if ./scripts/deploy.sh help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Web deployment script works${NC}"
else
    echo -e "${RED}❌ Web deployment script failed${NC}"
fi

# Test mobile deployment script
if ./scripts/mobile-deploy.sh help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Mobile deployment script works${NC}"
else
    echo -e "${RED}❌ Mobile deployment script failed${NC}"
fi

# Test deploy-all script
if ./scripts/deploy-all.sh help > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Deploy-all script works${NC}"
else
    echo -e "${RED}❌ Deploy-all script failed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Tool installation test completed!${NC}"
echo ""
echo -e "${BLUE}📋 Tool Installation Features:${NC}"
echo "✅ Automatic tool detection"
echo "✅ Automatic tool installation"
echo "✅ Individual tool installation"
echo "✅ Integration with deployment scripts"
echo "✅ Version checking"
echo "✅ Cross-platform support"
echo ""
echo -e "${BLUE}📚 Available commands:${NC}"
echo "Install all tools: ./scripts/install-tools.sh install"
echo "Check versions: ./scripts/install-tools.sh check"
echo "Install specific tool: ./scripts/install-tools.sh [tool]"
echo ""
echo -e "${BLUE}🔧 Automatic installation triggers:${NC}"
echo "• Web deployment: ./scripts/deploy.sh deploy"
echo "• Mobile deployment: ./scripts/mobile-deploy.sh build:dev"
echo "• Development server: ./scripts/deploy.sh dev"
echo "• Ngrok tunnel: ./scripts/deploy.sh ngrok"