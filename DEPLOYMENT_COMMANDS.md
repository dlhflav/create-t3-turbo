# 🚀 Deployment Commands

This document describes all available deployment commands for the T3 Turbo monorepo.

## 📦 Package-Level Commands

### Web App (@acme/nextjs)
```bash
# Development
pnpm -F @acme/nextjs dev          # Start development server
pnpm -F @acme/nextjs build        # Build for production
pnpm -F @acme/nextjs start        # Start production server

# Deployment
pnpm -F @acme/nextjs deploy:vercel # Deploy to Vercel (script)
pnpm -F @acme/nextjs deploy:local # Deploy locally (script)
pnpm -F @acme/nextjs deploy:tunnel # Start with local tunnel (script)
pnpm -F @acme/nextjs deploy:ngrok # Start with ngrok tunnel (script)
```

### Mobile App (@acme/expo)
```bash
# Development (Expo Go mode)
pnpm -F @acme/expo dev            # Start development server (Expo Go)
pnpm -F @acme/expo dev:tunnel     # Start with Expo tunnel (Expo Go)
pnpm -F @acme/expo dev:android    # Start for Android
pnpm -F @acme/expo dev:ios        # Start for iOS

# Deployment
pnpm -F @acme/expo deploy:local   # Start development with script
pnpm -F @acme/expo deploy:eas     # Build with EAS (all platforms) (script)
pnpm -F @acme/expo deploy:android # Build with EAS (Android) (script)
pnpm -F @acme/expo deploy:ios     # Build with EAS (iOS) (script)
pnpm -F @acme/expo deploy:tunnel  # Start with Expo tunnel
```

### Database Package (@acme/db)
```bash
# Development
pnpm -F @acme/db dev              # Compile TypeScript
pnpm -F @acme/db build            # Build package
pnpm -F @acme/db push             # Push schema to database
pnpm -F @acme/db studio           # Open Drizzle Studio
```

### Auth Package (@acme/auth)
```bash
# Development
pnpm -F @acme/auth generate       # Generate auth schema
```

## 🌐 Root-Level Commands

### Web Deployment
```bash
pnpm deploy:web:vercel            # Deploy web app to Vercel (subpackage)
pnpm deploy:web:local             # Deploy web app locally (subpackage)
pnpm deploy:web:tunnel            # Start web with local tunnel (subpackage)
pnpm deploy:web:ngrok             # Start web with ngrok tunnel (subpackage)
```

### Mobile Deployment
```bash
pnpm deploy:mobile:local          # Start mobile development (subpackage)
pnpm deploy:mobile:eas            # Deploy mobile app with EAS (subpackage)
pnpm deploy:mobile:android        # Deploy mobile app with EAS (Android) (subpackage)
pnpm deploy:mobile:ios            # Deploy mobile app with EAS (iOS) (subpackage)
pnpm deploy:mobile:tunnel         # Start mobile with Expo tunnel (subpackage)
```



### Complete Deployment
```bash
pnpm deploy:all                   # Complete build (script: Vercel + EAS)
```

## 🛠️ Script Commands

### Development Scripts
```bash
# Using the deploy.sh script
./scripts/deploy.sh web:dev       # Start web development server
./scripts/deploy.sh web:tunnel    # Start web with local tunnel
./scripts/deploy.sh web:ngrok-tunnel # Start web with ngrok tunnel
./scripts/deploy.sh web:vercel    # Deploy web to Vercel
./scripts/deploy.sh mobile:dev    # Start mobile development server
./scripts/deploy.sh mobile:tunnel # Start mobile with Expo tunnel
./scripts/deploy.sh mobile:all    # Build mobile app (development)
./scripts/deploy.sh mobile:deploy # EAS build for all platforms
./scripts/deploy.sh mobile:android # EAS build for Android
./scripts/deploy.sh mobile:ios    # EAS build for iOS
./scripts/deploy.sh all:local     # Complete local development
./scripts/deploy.sh all:tunnel    # Complete tunnel development
./scripts/deploy.sh all:build     # Complete build (Vercel + EAS)

# Stop commands
./scripts/deploy.sh stop:web      # Stop web servers
./scripts/deploy.sh stop:mobile   # Stop mobile servers
./scripts/deploy.sh stop:all      # Stop all servers

# Status
./scripts/deploy.sh status        # Show running processes
```

## 📋 Quick Start Examples

### Development
```bash
# Start web development
pnpm -F @acme/nextjs dev

# Start mobile development
pnpm -F @acme/expo dev

# Start both with script
./scripts/deploy.sh all:local
./scripts/deploy.sh all:tunnel
```

### Production Deployment
```bash
# Deploy web to Vercel
pnpm deploy:web:vercel

# Deploy mobile with EAS
pnpm deploy:mobile:eas

# Complete build (Vercel + EAS)
pnpm deploy:all
```

### Development with Tunnels
```bash
# Start web with local tunnel
pnpm deploy:web:tunnel

# Start web with ngrok tunnel
pnpm deploy:web:ngrok

# Start mobile with Expo tunnel
pnpm deploy:mobile:tunnel
```



## 🔧 Environment Setup

### Required Environment Variables
```bash
# Database
POSTGRES_URL=your_postgres_url

# Auth
AUTH_SECRET=your_auth_secret
AUTH_DISCORD_ID=your_discord_id
AUTH_DISCORD_SECRET=your_discord_secret

# Ngrok (optional)
NGROK_TOKEN=your_ngrok_token

# Vercel (optional)
VERCEL_TOKEN=your_vercel_token
```

### Prerequisites
```bash
# Install dependencies
pnpm install

# Setup database
pnpm -F @acme/db deploy:db

# Generate auth schema
pnpm -F @acme/auth deploy:generate
```

## 📊 Status Monitoring

The `status` command shows:
- ✅ Running processes with PIDs
- 🌐 Ngrok tunnel URLs
- 🔗 Local tunnel URLs
- 📝 Recent log output
- 🗂️ Process details with full names

## 📁 Log Files

- `web_output.log` - Web server output
- `web_tunnel_output.log` - Tunnel output (ngrok/localtunnel)
- `mobile_output.log` - Mobile server output

## 🔍 Process Information

The status command displays:
- **PIDs** for all running processes
- **Process names** with full command details
- **URLs** for all accessible endpoints
- **Recent output** from log files

## 🚨 Troubleshooting

### Common Issues
1. **Port conflicts**: Check if ports 3000, 8081, 4040 are available
2. **Environment variables**: Ensure all required env vars are set
3. **Database connection**: Verify POSTGRES_URL is correct
4. **Auth setup**: Run `pnpm -F @acme/auth deploy:generate` if auth fails

### Clean Restart
```bash
# Stop all processes
./scripts/deploy.sh stop:all

# Clean logs
./scripts/deploy.sh clean:logs

# Restart
./scripts/deploy.sh web:dev
./scripts/deploy.sh mobile:dev
```