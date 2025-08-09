# Ngrok Setup for Expo Mobile App

## Quick Setup (Recommended)

### 1. Get Free Ngrok Account
1. Go to https://dashboard.ngrok.com/signup
2. Sign up with your email (free account)
3. Verify your email
4. Go to https://dashboard.ngrok.com/get-started/your-authtoken
5. Copy your auth token

### 2. Configure Ngrok
```bash
# Add your auth token
ngrok config add-authtoken YOUR_TOKEN_HERE

# Verify configuration
ngrok config check
```

### 3. Start Expo with Ngrok Tunnel
```bash
# Option 1: Use the script
pnpm dev:ngrok

# Option 2: Manual
expo start --lan & sleep 10 && ngrok http 8081
```

## Alternative Methods

### Method 1: Environment Variable
Create `.env` file in root directory:
```bash
NGROK_AUTHTOKEN=your_ngrok_token_here
```

### Method 2: Direct Configuration
```bash
# Configure ngrok directly
ngrok config add-authtoken YOUR_TOKEN_HERE

# Start tunnel
ngrok http 8081
```

## Verification

After setup, you can:
1. Check tunnel status: http://localhost:4040
2. Get tunnel URL: `curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'])"`

## Troubleshooting

### Common Issues
- **"authentication failed"**: Need to add auth token
- **"Cannot use ngrok with a robot user"**: Need verified account
- **Port already in use**: Stop other processes on port 8081

### Solutions
1. Ensure ngrok is authenticated: `ngrok config check`
2. Check if port 8081 is free: `lsof -i :8081`
3. Restart Expo server: `pkill -f expo && expo start --lan`

## Commands Added

The following scripts are available in `package.json`:
- `dev:tunnel`: Expo with built-in tunnel (requires auth)
- `dev:ngrok`: Expo + ngrok tunnel (requires auth)
- `dev:localtunnel`: Expo + localtunnel (no auth required)