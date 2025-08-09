#!/bin/bash

echo "🚀 Setting up ngrok for Expo Mobile App"
echo "========================================"

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok is not installed. Installing..."
    curl -L https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install ngrok -y
    echo "✅ ngrok installed successfully"
else
    echo "✅ ngrok is already installed"
fi

# Check if auth token is configured
if [ -f ~/.config/ngrok/ngrok.yml ]; then
    echo "✅ ngrok is already configured"
else
    echo "❌ ngrok needs authentication"
    echo ""
    echo "To get a free ngrok auth token:"
    echo "1. Go to https://dashboard.ngrok.com/signup"
    echo "2. Sign up for a free account"
    echo "3. Go to https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "4. Copy your auth token"
    echo ""
    echo "Then run: ngrok config add-authtoken YOUR_TOKEN_HERE"
    echo ""
    echo "Or set NGROK_AUTHTOKEN in your .env file and run this script again"
    exit 1
fi

echo ""
echo "🎉 ngrok is ready!"
echo ""
echo "To start Expo with ngrok tunnel:"
echo "  pnpm dev:ngrok"
echo ""
echo "Or manually:"
echo "  expo start --lan & sleep 10 && ngrok http 8081"
echo ""
echo "The tunnel URL will be available at: http://localhost:4040"