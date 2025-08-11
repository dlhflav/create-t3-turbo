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
pnpm -F @acme/nextjs deploy       # Build and start locally
pnpm -F @acme/nextjs deploy:vercel # Build and deploy to Vercel
pnpm -F @acme/nextjs deploy:local # Build and start locally
```

### Mobile App (@acme/expo)
```bash
# Development
pnpm -F @acme/expo dev            # Start development server
pnpm -F @acme/expo dev:tunnel     # Start with Expo tunnel
pnpm -F @acme/expo dev:android    # Start for Android
pnpm -F @acme/expo dev:ios        # Start for iOS

# Deployment
pnpm -F @acme/expo deploy         # Build for Android and iOS
pnpm -F @acme/expo deploy:android # Build for Android only
pnpm -F @acme/expo deploy:ios     # Build for iOS only
pnpm -F @acme/expo deploy:web     # Build for web
pnpm -F @acme/expo deploy:eas     # Build with EAS (all platforms)
pnpm -F @acme/expo deploy:eas:android # Build with EAS (Android)
pnpm -F @acme/expo deploy:eas:ios # Build with EAS (iOS)
```

### API Package (@acme/api)
```bash
# Development
pnpm -F @acme/api dev             # Compile TypeScript
pnpm -F @acme/api build           # Build package

# Deployment
pnpm -F @acme/api deploy          # Build and publish to npm
pnpm -F @acme/api deploy:dry-run  # Test publish without publishing
pnpm -F @acme/api deploy:local    # Build only (local use)
```

### Database Package (@acme/db)
```bash
# Development
pnpm -F @acme/db dev              # Compile TypeScript
pnpm -F @acme/db build            # Build package
pnpm -F @acme/db push             # Push schema to database
pnpm -F @acme/db studio           # Open Drizzle Studio

# Deployment
pnpm -F @acme/db deploy           # Build and publish to npm
pnpm -F @acme/db deploy:dry-run   # Test publish without publishing
pnpm -F @acme/db deploy:local     # Build only (local use)
pnpm -F @acme/db deploy:db        # Push schema to database
pnpm -F @acme/db deploy:db:studio # Open Drizzle Studio
```

### UI Package (@acme/ui)
```bash
# Development
pnpm -F @acme/ui build            # Build package
pnpm -F @acme/ui ui-add           # Add new UI component

# Deployment
pnpm -F @acme/ui deploy           # Build and publish to npm
pnpm -F @acme/ui deploy:dry-run   # Test publish without publishing
pnpm -F @acme/ui deploy:local     # Build only (local use)
```

### Validators Package (@acme/validators)
```bash
# Development
pnpm -F @acme/validators dev      # Compile TypeScript
pnpm -F @acme/validators build    # Build package

# Deployment
pnpm -F @acme/validators deploy   # Build and publish to npm
pnpm -F @acme/validators deploy:dry-run # Test publish without publishing
pnpm -F @acme/validators deploy:local # Build only (local use)
```

### Auth Package (@acme/auth)
```bash
# Development
pnpm -F @acme/auth build          # Build package
pnpm -F @acme/auth generate       # Generate auth schema

# Deployment
pnpm -F @acme/auth deploy         # Build and publish to npm
pnpm -F @acme/auth deploy:dry-run # Test publish without publishing
pnpm -F @acme/auth deploy:local   # Build only (local use)
pnpm -F @acme/auth deploy:generate # Generate auth schema
```

## 🌐 Root-Level Commands

### Web Deployment
```bash
pnpm deploy                       # Deploy web app (default)
pnpm deploy:web                   # Deploy web app
pnpm deploy:web:vercel            # Deploy web app to Vercel
pnpm deploy:web:local             # Deploy web app locally
```

### Mobile Deployment
```bash
pnpm deploy:mobile                # Deploy mobile app (all platforms)
pnpm deploy:mobile:android        # Deploy mobile app (Android)
pnpm deploy:mobile:ios            # Deploy mobile app (iOS)
pnpm deploy:mobile:web            # Deploy mobile app (web)
pnpm deploy:mobile:eas            # Deploy mobile app with EAS
```

### Package Deployment
```bash
pnpm deploy:packages              # Deploy all packages to npm
pnpm deploy:packages:dry-run      # Test deploy all packages
```

### Complete Deployment
```bash
pnpm deploy:all                   # Deploy everything (packages + web + mobile)
```

## 🛠️ Script Commands

### Development Scripts
```bash
# Using the deploy.sh script
./scripts/deploy.sh web:dev       # Start web development server
./scripts/deploy.sh web:tunnel    # Start web with local tunnel
./scripts/deploy.sh web:ngrok-tunnel # Start web with ngrok tunnel
./scripts/deploy.sh mobile:dev    # Start mobile development server
./scripts/deploy.sh mobile:tunnel # Start mobile with Expo tunnel
./scripts/deploy.sh all:web       # Complete web deployment
./scripts/deploy.sh all:mobile    # Complete mobile deployment

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
./scripts/deploy.sh web:dev
./scripts/deploy.sh mobile:dev
```

### Production Deployment
```bash
# Deploy web to Vercel
pnpm deploy:web:vercel

# Deploy mobile with EAS
pnpm deploy:mobile:eas

# Deploy all packages
pnpm deploy:packages

# Deploy everything
pnpm deploy:all
```

### Package Publishing
```bash
# Test publish (dry run)
pnpm -F @acme/ui deploy:dry-run

# Publish package
pnpm -F @acme/ui deploy

# Publish all packages
pnpm deploy:packages
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