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

### Using the Script
```bash
chmod +x scripts/deploy.sh

./scripts/deploy.sh dev      # Development server
./scripts/deploy.sh ngrok    # Ngrok tunnel
./scripts/deploy.sh tunnel   # Dev + ngrok
./scripts/deploy.sh deploy   # Deploy to Vercel (10min timeout)
./scripts/deploy.sh all      # Everything
./scripts/deploy.sh status   # Check status
```

### Timeout Options
```bash
# Default timeout (10 minutes)
./scripts/deploy.sh deploy

# Custom timeout (15 minutes)
VERCEL_TIMEOUT=900 ./scripts/deploy.sh deploy

# Quick timeout for testing (2 minutes)
VERCEL_TIMEOUT=120 ./scripts/deploy.sh deploy
```

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

### Getting Help
- [T3 Turbo docs](https://github.com/t3-oss/create-t3-turbo)
- [Vercel docs](https://vercel.com/docs)
- [Ngrok docs](https://ngrok.com/docs)

---

## 🎉 Success!

- **Development**: Use ngrok tunnel (changes on restart)
- **Production**: Use Vercel (permanent URL)
- **Monitoring**: Check deployment status with `./scripts/deploy.sh status`