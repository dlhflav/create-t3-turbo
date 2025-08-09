# 🚀 T3 Turbo Deployment Guide

## 🛠️ Quick Deployment Script

### Setup Tokens

#### Option 1: Cursor Secrets (Recommended)
1. **Add tokens to Cursor Secrets**:
   - Open Cursor Settings → Secrets
   - Add: `VERCEL_TOKEN=your-vercel-token` and `NGROK_AUTHTOKEN=your-ngrok-token`
2. **Restart the agent** to access secrets

#### Option 2: Environment File
```bash
cp .env.example .env
# Add VERCEL_TOKEN and NGROK_AUTHTOKEN to .env
```

### Using the Scripts

#### Individual Scripts
```bash
chmod +x scripts/deploy.sh scripts/mobile-deploy.sh scripts/deploy-all.sh

# Web only
./scripts/deploy.sh dev      # Development server
./scripts/deploy.sh ngrok    # Ngrok tunnel
./scripts/deploy.sh tunnel   # Dev + ngrok
./scripts/deploy.sh deploy   # Deploy to Vercel (3min timeout)
./scripts/deploy.sh status   # Check status

# Mobile only
./scripts/mobile-deploy.sh dev         # Start Expo dev server
./scripts/mobile-deploy.sh build:dev   # Build development version
./scripts/mobile-deploy.sh build:prod  # Build production version
./scripts/mobile-deploy.sh status      # Check build metrics
```

#### Combined Script (Recommended)
```bash
./scripts/deploy-all.sh web:dev      # Web development
./scripts/deploy-all.sh web:deploy   # Web production
./scripts/deploy-all.sh mobile:dev   # Mobile development
./scripts/deploy-all.sh mobile:build # Mobile build
./scripts/deploy-all.sh all:web      # Complete web deployment
./scripts/deploy-all.sh all:mobile   # Complete mobile deployment
./scripts/deploy-all.sh status       # All services status
```

### Timeout Options
```bash
# Default timeout (3 minutes)
./scripts/deploy.sh deploy

# Custom timeout (10 minutes)
VERCEL_TIMEOUT=600 ./scripts/deploy.sh deploy

# Quick timeout for testing (1 minute)
VERCEL_TIMEOUT=60 ./scripts/deploy.sh deploy
```

---

## 📱 Mobile App Deployment

### Prerequisites
- **Expo account**: [expo.dev](https://expo.dev)
- **EAS CLI**: `npm install -g eas-cli`
- **Authentication**: Choose one:
  - **Interactive**: `eas login`
  - **Access Token**: Create at [expo.dev/accounts/[username]/settings/access-tokens](https://expo.dev/accounts/[username]/settings/access-tokens)
  - **Environment**: Set `EXPO_TOKEN=your_token` in Cursor Secrets or `.env`

### Using the Mobile Script
```bash
chmod +x scripts/mobile-deploy.sh

./scripts/mobile-deploy.sh dev         # Start Expo dev server
./scripts/mobile-deploy.sh build:dev   # Build development version
./scripts/mobile-deploy.sh build:preview # Build preview version
./scripts/mobile-deploy.sh build:prod  # Build production version
./scripts/mobile-deploy.sh submit      # Submit to app stores
./scripts/mobile-deploy.sh status      # Check build metrics
```

### Build Types
- **Development**: For testing with Expo Go
- **Preview**: Internal distribution for testing
- **Production**: App store ready builds

### Expected Build Times
- **Development**: 5-10 minutes
- **Preview**: 10-15 minutes  
- **Production**: 15-25 minutes

---

## 🚀 Vercel Production Deployment

### Prerequisites
- Vercel account: [vercel.com](https://vercel.com)
- Vercel CLI: `npm install -g vercel`
- Vercel token: [vercel.com/account/tokens](https://vercel.com/account/tokens)

### Quick Deploy
```bash
vercel --token $VERCEL_TOKEN --yes --prod
```

### Expected Times
- **First deployment**: 2-5 minutes
- **Subsequent**: 30-90 seconds

---

## 🔧 Ngrok Development Tunnel

### Setup
```bash
# Install ngrok
curl -L https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Configure
ngrok config add-authtoken $NGROK_AUTHTOKEN

# Start tunnel
ngrok http 3000
```

### Features
- **Public URL**: Automatically generated (changes on restart)
- **Monitor**: http://localhost:4040
- **Timeout**: 8 hours (free plan)

---

## 🆘 Quick Troubleshooting

### Common Issues
- **Build fails**: Check Node.js version (>=22.14.0)
- **Token errors**: Verify tokens in Cursor Secrets or .env
- **Port conflicts**: Change port in `apps/nextjs/package.json`
- **Slow deployments**: Check build cache
- **Deployment timeout**: Increase VERCEL_TIMEOUT or check Vercel status
- **Mobile build fails**: Check Expo login and EAS configuration
- **Expo authentication fails**: Create access token at expo.dev/accounts/[username]/settings/access-tokens

### Getting Help
- [T3 Turbo docs](https://github.com/t3-oss/create-t3-turbo)
- [Vercel docs](https://vercel.com/docs)
- [Ngrok docs](https://ngrok.com/docs)
- [Expo docs](https://docs.expo.dev)

---

## 🎉 Success!

- **Development**: Use ngrok tunnel (changes on restart)
- **Production**: Use Vercel (permanent URL)
- **Mobile**: Use EAS builds (app store ready)
- **Monitoring**: Check all services with `./scripts/deploy-all.sh status`
- **Quick Deploy**: Use `./scripts/deploy-all.sh all:web` for complete web deployment
- **Mobile Deploy**: Use `./scripts/deploy-all.sh all:mobile` for complete mobile deployment