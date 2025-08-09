# Mobile Deployment Guide

This guide covers the complete mobile deployment setup and usage for the T3 Turbo monorepo.

## Overview

The mobile deployment system consists of several scripts that handle Expo mobile app development, building, and deployment:

- **`scripts/mobile-deploy.sh`** - Main mobile deployment script
- **`scripts/deploy-all.sh`** - Orchestrates both web and mobile deployments
- **`scripts/test-mobile.sh`** - Tests all mobile deployment functionality
- **`scripts/install-tools.sh`** - Automatic tool installation and management

## Prerequisites

### Required Tools

The deployment system will **automatically install** all required tools if they're missing:

1. **Node.js** (>=22.14.0)
2. **pnpm** (>=9.6.0)
3. **EAS CLI** - Expo Application Services CLI
4. **Vercel CLI** - For web deployments
5. **ngrok** - For development tunneling
6. **Python 3** - For ngrok tunnel parsing
7. **curl** - For health checks

### Automatic Installation

All tools are automatically installed when needed:

```bash
# Tools are automatically installed when running deployment commands
./scripts/mobile-deploy.sh build:dev  # Installs EAS CLI if missing
./scripts/deploy.sh deploy            # Installs Vercel CLI if missing
./scripts/deploy.sh ngrok             # Installs ngrok if missing
```

### Manual Installation

You can also install tools manually:

```bash
# Install all tools at once
./scripts/install-tools.sh install

# Check current tool versions
./scripts/install-tools.sh check

# Install specific tools
./scripts/install-tools.sh eas        # Install EAS CLI only
./scripts/install-tools.sh vercel     # Install Vercel CLI only
./scripts/install-tools.sh ngrok      # Install ngrok only
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

# Test tool installation specifically
./scripts/test-tools.sh
```

### 2. Start Development Server

```bash
# Start the Expo development server (tools installed automatically)
./scripts/mobile-deploy.sh dev
```

This will:
- **Automatically install** any missing tools
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
# Start development server (auto-installs tools)
./scripts/mobile-deploy.sh dev

# Check status of all services
./scripts/mobile-deploy.sh status
```

### Build Commands

```bash
# Build development version (auto-installs tools)
./scripts/mobile-deploy.sh build:dev

# Build preview version (auto-installs tools)
./scripts/mobile-deploy.sh build:preview

# Build production version (auto-installs tools)
./scripts/mobile-deploy.sh build:prod
```

### Deployment Commands

```bash
# Submit to app stores
./scripts/mobile-deploy.sh submit

# Configure build credentials
./scripts/mobile-deploy.sh credentials
```

### Tool Management Commands

```bash
# Install all required tools
./scripts/install-tools.sh install

# Check tool versions
./scripts/install-tools.sh check

# Install specific tools
./scripts/install-tools.sh eas
./scripts/install-tools.sh vercel
./scripts/install-tools.sh ngrok
./scripts/install-tools.sh pnpm
```

### Combined Commands (via deploy-all.sh)

```bash
# Start mobile development (auto-installs tools)
./scripts/deploy-all.sh mobile:dev

# Build mobile app (auto-installs tools)
./scripts/deploy-all.sh mobile:build

# Build mobile app (production) (auto-installs tools)
./scripts/deploy-all.sh mobile:prod

# Configure mobile credentials
./scripts/deploy-all.sh mobile:credentials

# Complete mobile deployment (auto-installs tools)
./scripts/deploy-all.sh all:mobile

# Check all services status
./scripts/deploy-all.sh status

# Install all tools manually
./scripts/deploy-all.sh install
```

## Automatic Tool Installation

### How It Works

The deployment scripts automatically check for required tools and install them if missing:

1. **Detection**: Scripts check if tools are available in PATH
2. **Installation**: Missing tools are automatically installed via npm
3. **Verification**: Tools are verified to be working
4. **Proceeding**: Deployment continues with all tools available

### Installation Triggers

Tools are automatically installed when running:

- **Web Deployment**: `./scripts/deploy.sh deploy`
- **Mobile Build**: `./scripts/mobile-deploy.sh build:dev`
- **Development Server**: `./scripts/deploy.sh dev`
- **Ngrok Tunnel**: `./scripts/deploy.sh ngrok`
- **Any deployment command**: Tools are checked first

### Supported Platforms

- **Linux**: Full automatic installation support
- **macOS**: Manual installation guidance provided
- **Windows**: Manual installation guidance provided

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

1. **Tools not installing automatically**
   ```bash
   # Manual installation
   ./scripts/install-tools.sh install
   ```

2. **Permission issues**
   ```bash
   # Make scripts executable
   chmod +x scripts/*.sh
   ```

3. **Not logged in to Expo**
   ```bash
   eas login
   ```

4. **Build fails due to credentials**
   ```bash
   ./scripts/mobile-deploy.sh credentials
   ```

5. **Development server not starting**
   ```bash
   # Tools will be auto-installed
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
5. **Let tools auto-install** - no need to pre-install everything

## Metrics and Monitoring

The deployment scripts automatically track:

- Build times
- Success/failure rates
- Deployment durations
- Service status
- Tool installation status

View metrics with:
```bash
./scripts/mobile-deploy.sh status
./scripts/deploy-all.sh status
```

## Integration with Web Deployment

The mobile deployment integrates seamlessly with the web deployment system:

```bash
# Deploy both web and mobile (tools auto-installed)
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

1. **Let tools auto-install** - Don't worry about pre-installing everything
2. **Always test with development server first**
3. **Use preview builds for testing**
4. **Configure credentials early in development**
5. **Monitor build metrics for optimization**
6. **Keep tools updated** - Use `./scripts/install-tools.sh check`
7. **Use the test scripts** to verify setup

## Support

For issues with:
- **Expo/EAS**: [docs.expo.dev](https://docs.expo.dev)
- **Build failures**: Check the build logs in Expo dashboard
- **Script issues**: Run `./scripts/test-mobile.sh` for diagnostics
- **Tool installation**: Run `./scripts/test-tools.sh` for tool diagnostics

## Next Steps

1. ✅ Test the setup with `./scripts/test-mobile.sh`
2. ✅ Test tool installation with `./scripts/test-tools.sh`
3. ✅ Start development server with `./scripts/mobile-deploy.sh dev`
4. 🔧 Configure credentials for builds
5. 🚀 Build and deploy your mobile app
6. 📱 Submit to app stores when ready