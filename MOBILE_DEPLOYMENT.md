# Mobile Deployment Guide

This guide covers the complete mobile deployment setup and usage for the T3 Turbo monorepo.

## Overview

The mobile deployment system consists of several scripts that handle Expo mobile app development, building, and deployment:

- **`scripts/mobile-deploy.sh`** - Main mobile deployment script
- **`scripts/deploy-all.sh`** - Orchestrates both web and mobile deployments
- **`scripts/test-mobile.sh`** - Tests all mobile deployment functionality

## Prerequisites

### Required Tools

1. **Node.js** (>=22.14.0)
2. **pnpm** (>=9.6.0)
3. **EAS CLI** - Expo Application Services CLI
4. **Expo Account** - For builds and deployments

### Installation

```bash
# Install EAS CLI globally
npm install -g eas-cli

# Install other tools if needed
npm install -g pnpm
```

### Authentication

1. **Expo Login**: Create an account at [expo.dev](https://expo.dev)
2. **Login via CLI**: `eas login`
3. **Access Token** (optional): For automated deployments, create an access token at [expo.dev/accounts/[username]/settings/access-tokens](https://expo.dev/accounts/[username]/settings/access-tokens)

## Quick Start

### 1. Test the Setup

```bash
# Run the test script to verify everything is working
./scripts/test-mobile.sh
```

### 2. Start Development Server

```bash
# Start the Expo development server
./scripts/mobile-deploy.sh dev
```

This will:
- Install dependencies if needed
- Start the development server on `http://localhost:8081`
- Display QR code for mobile testing
- Provide web browser option

### 3. Configure Build Credentials (for builds)

```bash
# Configure credentials for building
./scripts/mobile-deploy.sh credentials
```

This interactive command will help you set up:
- Android keystore and credentials
- iOS certificates and provisioning profiles

## Available Commands

### Development Commands

```bash
# Start development server
./scripts/mobile-deploy.sh dev

# Check status of all services
./scripts/mobile-deploy.sh status
```

### Build Commands

```bash
# Build development version
./scripts/mobile-deploy.sh build:dev

# Build preview version
./scripts/mobile-deploy.sh build:preview

# Build production version
./scripts/mobile-deploy.sh build:prod
```

### Deployment Commands

```bash
# Submit to app stores
./scripts/mobile-deploy.sh submit

# Configure build credentials
./scripts/mobile-deploy.sh credentials
```

### Combined Commands (via deploy-all.sh)

```bash
# Start mobile development
./scripts/deploy-all.sh mobile:dev

# Build mobile app
./scripts/deploy-all.sh mobile:build

# Build mobile app (production)
./scripts/deploy-all.sh mobile:prod

# Configure mobile credentials
./scripts/deploy-all.sh mobile:credentials

# Complete mobile deployment
./scripts/deploy-all.sh all:mobile

# Check all services status
./scripts/deploy-all.sh status
```

## Project Configuration

### EAS Configuration (`apps/expo/eas.json`)

```json
{
  "cli": {
    "version": ">= 4.1.2",
    "appVersionSource": "remote"
  },
  "build": {
    "base": {
      "node": "22.12.0",
      "pnpm": "9.15.4"
    },
    "development": {
      "extends": "base",
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "extends": "base",
      "distribution": "internal"
    },
    "production": {
      "extends": "base"
    }
  },
  "submit": {
    "production": {}
  }
}
```

### App Configuration (`apps/expo/app.config.ts`)

The app configuration includes:
- Bundle identifiers for iOS and Android
- App icons and splash screens
- Expo plugins configuration
- Environment variables

## Build Profiles

### Development Build
- **Purpose**: For testing with development features
- **Distribution**: Internal (Expo Go compatible)
- **Features**: Development client, debugging tools

### Preview Build
- **Purpose**: For testing before production
- **Distribution**: Internal
- **Features**: Production-like environment

### Production Build
- **Purpose**: For app store submission
- **Distribution**: Store
- **Features**: Optimized, production-ready

## Troubleshooting

### Common Issues

1. **EAS CLI not found**
   ```bash
   npm install -g eas-cli
   ```

2. **Not logged in to Expo**
   ```bash
   eas login
   ```

3. **Build fails due to credentials**
   ```bash
   ./scripts/mobile-deploy.sh credentials
   ```

4. **Development server not starting**
   ```bash
   cd apps/expo && pnpm install
   ./scripts/mobile-deploy.sh dev
   ```

### Build Failures

- **Android**: Check keystore configuration
- **iOS**: Verify certificates and provisioning profiles
- **Network**: Ensure stable internet connection
- **Timeout**: First builds take longer, subsequent builds are faster

### Performance Tips

1. **Use development server** for quick testing
2. **Configure credentials once** for faster builds
3. **Use preview builds** for testing before production
4. **Monitor build metrics** with status command

## Metrics and Monitoring

The deployment scripts automatically track:

- Build times
- Success/failure rates
- Deployment durations
- Service status

View metrics with:
```bash
./scripts/mobile-deploy.sh status
```

## Integration with Web Deployment

The mobile deployment integrates seamlessly with the web deployment system:

```bash
# Deploy both web and mobile
./scripts/deploy-all.sh all:web
./scripts/deploy-all.sh all:mobile

# Check all services
./scripts/deploy-all.sh status
```

## Environment Variables

Create a `.env` file in the root directory for automated deployments:

```env
# Expo (optional)
EXPO_TOKEN=your_expo_access_token

# Other deployment tokens
VERCEL_TOKEN=your_vercel_token
NGROK_AUTHTOKEN=your_ngrok_token
```

## Best Practices

1. **Always test with development server first**
2. **Use preview builds for testing**
3. **Configure credentials early in development**
4. **Monitor build metrics for optimization**
5. **Keep EAS CLI and dependencies updated**
6. **Use the test script to verify setup**

## Support

For issues with:
- **Expo/EAS**: [docs.expo.dev](https://docs.expo.dev)
- **Build failures**: Check the build logs in Expo dashboard
- **Script issues**: Run `./scripts/test-mobile.sh` for diagnostics

## Next Steps

1. ✅ Test the setup with `./scripts/test-mobile.sh`
2. ✅ Start development server with `./scripts/mobile-deploy.sh dev`
3. 🔧 Configure credentials for builds
4. 🚀 Build and deploy your mobile app
5. 📱 Submit to app stores when ready