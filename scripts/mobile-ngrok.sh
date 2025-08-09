#!/bin/bash

# Mobile Ngrok Script for Expo App
# Based on the existing deploy.sh script but adapted for mobile

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables from .env file
if [ -f .env ]; then
    echo -e "${BLUE}📄 Loading environment variables from .env${NC}"
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z $line ]] && continue
        
        # Only export NGROK_TOKEN
        if [[ $line =~ ^NGROK_TOKEN= ]]; then
            export "$line"
        fi
    done < .env
else
    echo -e "${YELLOW}⚠️ .env file not found, using environment variables${NC}"
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

# Function to start ngrok tunnel for mobile
start_mobile_ngrok() {
    echo -e "${BLUE}🚀 Starting ngrok tunnel for mobile app...${NC}"
    
    if ! check_token "NGROK_TOKEN" "$NGROK_TOKEN"; then
        echo -e "${YELLOW}⚠️ Skipping ngrok - token not configured${NC}"
        echo -e "${BLUE}💡 To set up ngrok:${NC}"
        echo "1. Get free token: https://dashboard.ngrok.com/signup"
        echo "2. Add to .env: NGROK_TOKEN=your_token_here"
        return 1
    fi
    
    # Configure ngrok if not already configured
    if [ ! -f ~/.config/ngrok/ngrok.yml ]; then
        echo -e "${BLUE}⚙️ Configuring ngrok...${NC}"
        ngrok config add-authtoken "$NGROK_TOKEN"
    fi
    
    # Start ngrok tunnel on port 8081 (Expo default)
    echo -e "${GREEN}✅ Starting ngrok tunnel on port 8081...${NC}"
    ngrok http 8081 &
    NGROK_PID=$!
    
    # Wait a moment for ngrok to start
    sleep 5
    
    # Get the tunnel URL
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])" 2>/dev/null || echo "Unknown")
        echo -e "${GREEN}🎉 Ngrok tunnel started: $TUNNEL_URL${NC}"
        echo -e "${BLUE}📊 Monitor at: http://localhost:4040${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start ngrok tunnel${NC}"
        return 1
    fi
}

# Function to start Expo development server
start_expo() {
    echo -e "${BLUE}📱 Starting Expo development server...${NC}"
    
    # Navigate to Expo app directory
    cd apps/expo
    
    # Start Expo server
    echo -e "${GREEN}✅ Starting Expo server on http://localhost:8081${NC}"
    expo start --lan &
    EXPO_PID=$!
    
    # Wait for server to start
    sleep 10
    
    # Check if server is running
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Expo server is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start Expo server${NC}"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}📱 Mobile Ngrok Script${NC}"
    echo "This script handles ngrok tunneling for the Expo mobile app"
    echo ""
    echo -e "${GREEN}Commands:${NC}"
    echo "  expo     - Start Expo development server only"
    echo "  ngrok    - Start ngrok tunnel only (port 8081)"
    echo "  tunnel   - Start Expo server + ngrok tunnel"
    echo "  status   - Show current status"
    echo "  help     - Show this help"
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  Make sure to set NGROK_TOKEN in .env file"
    echo ""
    echo -e "${BLUE}Example:${NC}"
    echo "  ./scripts/mobile-ngrok.sh tunnel"
}

# Function to show status
show_status() {
    echo -e "${BLUE}📊 Current Status${NC}"
    echo ""
    
    # Check if Expo server is running
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Expo server: Running on http://localhost:8081${NC}"
    else
        echo -e "${RED}❌ Expo server: Not running${NC}"
    fi
    
    # Check if ngrok is running
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])" 2>/dev/null || echo "Unknown")
        echo -e "${GREEN}✅ Ngrok tunnel: $TUNNEL_URL${NC}"
        echo -e "${BLUE}📊 Monitor: http://localhost:4040${NC}"
    else
        echo -e "${RED}❌ Ngrok tunnel: Not running${NC}"
    fi
}

# Main script logic
case "${1:-help}" in
    "expo")
        start_expo
        echo -e "${GREEN}🎉 Expo server started!${NC}"
        echo -e "${BLUE}Press Ctrl+C to stop${NC}"
        wait $EXPO_PID
        ;;
    "ngrok")
        start_mobile_ngrok
        echo -e "${GREEN}🎉 Ngrok tunnel started!${NC}"
        echo -e "${BLUE}Press Ctrl+C to stop${NC}"
        wait $NGROK_PID
        ;;
    "tunnel")
        start_expo
        if [ $? -eq 0 ]; then
            start_mobile_ngrok
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}🎉 Expo server and ngrok tunnel started!${NC}"
                echo -e "${BLUE}Press Ctrl+C to stop${NC}"
                wait $EXPO_PID $NGROK_PID
            else
                echo -e "${RED}❌ Failed to start ngrok tunnel${NC}"
                kill $EXPO_PID 2>/dev/null || true
            fi
        else
            echo -e "${RED}❌ Failed to start Expo server${NC}"
        fi
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_usage
        ;;
esac