#!/bin/bash

echo "🔑 Getting Free Ngrok Auth Token"
echo "================================"

# Function to check if ngrok is authenticated
check_ngrok_auth() {
    if ngrok config check >/dev/null 2>&1; then
        echo "✅ ngrok is already authenticated"
        return 0
    else
        echo "❌ ngrok needs authentication"
        return 1
    fi
}

# Check if already authenticated
if check_ngrok_auth; then
    echo ""
    echo "🎉 ngrok is ready to use!"
    echo ""
    echo "To start Expo with ngrok tunnel:"
    echo "  pnpm dev:ngrok"
    echo ""
    echo "Or manually:"
    echo "  expo start --lan & sleep 10 && ngrok http 8081"
    exit 0
fi

echo ""
echo "📋 To get a FREE ngrok auth token:"
echo ""
echo "1. 🌐 Go to: https://dashboard.ngrok.com/signup"
echo "2. 📧 Sign up with your email (FREE account)"
echo "3. ✅ Verify your email"
echo "4. 🔑 Go to: https://dashboard.ngrok.com/get-started/your-authtoken"
echo "5. 📋 Copy your auth token"
echo ""
echo "Then run one of these commands:"
echo ""
echo "Option 1 - Direct configuration:"
echo "  ngrok config add-authtoken YOUR_TOKEN_HERE"
echo ""
echo "Option 2 - Environment variable:"
echo "  echo 'NGROK_AUTHTOKEN=YOUR_TOKEN_HERE' >> /workspace/.env"
echo ""
echo "After adding the token, run this script again to verify setup."
echo ""
echo "💡 Quick start after getting token:"
echo "  pnpm dev:ngrok"