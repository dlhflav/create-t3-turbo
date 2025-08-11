# Discord Auth Development Tunnel

This setup allows you to develop Discord OAuth authentication locally while maintaining a stable, public URL for Discord's OAuth callback.

## 🎯 Problem Solved

- **Development logs in console**: You can see all your Next.js development logs locally
- **Stable OAuth callback URL**: Discord gets a consistent HTTPS URL that doesn't change
- **No production deployment needed**: Everything runs locally with a tunnel

## 🚀 Quick Start

### Option 1: Using Environment Variable (Recommended)

#### 1. Set Your Tunnel Subdomain

Add to your `.env` file:

```bash
# Set your custom subdomain for tunnels
TUNNEL_SUBDOMAIN="my-app-oauth-2024"
```

#### 2. Start Development Tunnel

```bash
# This will automatically use your TUNNEL_SUBDOMAIN
pnpm dev:discord-auth
# or
pnpm deploy:web:tunnel
```

### Option 2: Using Discord Auth Config File

#### 1. Configure Your Tunnel

Edit `scripts/discord-auth-config.sh`:

```bash
# Change this to a unique subdomain for your app
export DISCORD_AUTH_SUBDOMAIN="my-app-discord-auth-2024"
```

#### 2. Start Development Tunnel

```bash
pnpm dev:discord-auth
```

### Option 3: Using Command Line

#### 1. Check Subdomain Availability

```bash
# Check if your desired subdomain is available
pnpm check-subdomain my-awesome-app
```

#### 2. Start with Custom Subdomain

```bash
# Start web development with custom subdomain
pnpm deploy:web:tunnel-custom my-awesome-app
```

### 3. Configure Discord OAuth

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create or select your application
3. Go to **OAuth2 → General**
4. Add redirect URL: `https://your-subdomain.loca.lt/api/auth/callback/discord`
5. Copy Client ID and Client Secret to your `.env` file

### 4. Test Authentication

Visit your local development URL: `http://localhost:3000`

## 📋 What You'll See

When you run `pnpm dev:discord-auth`, you'll see:

```
🎉 Discord Auth Development Tunnel Ready!

📱 Local Development: http://localhost:3000
🌐 Public Tunnel URL: https://your-subdomain.loca.lt

🔗 Discord OAuth Callback URL:
   https://your-subdomain.loca.lt/api/auth/callback/discord

⚠️  Add this URL to your Discord OAuth app settings:
   https://your-subdomain.loca.lt/api/auth/callback/discord

📝 All development logs will appear in your console
🛑 Press Ctrl+C to stop both server and tunnel
```

## ⚙️ Configuration Options

### Environment Variable (Recommended)

Set in your `.env` file:

- **TUNNEL_SUBDOMAIN**: Your stable subdomain (takes precedence over all other methods)

### Discord Auth Script Configuration

Edit `scripts/discord-auth-config.sh` to customize:

- **DISCORD_AUTH_SUBDOMAIN**: Your stable subdomain (used if TUNNEL_SUBDOMAIN is not set)
- **DEV_PORT**: Local development port (default: 3000)
- **TUNNEL_SERVICE**: Tunnel service (local or ngrok)

### Main Deploy Script Commands

- **`pnpm deploy:web:tunnel`**: Start with TUNNEL_SUBDOMAIN or random subdomain
- **`pnpm deploy:web:tunnel-custom <subdomain>`**: Start with custom subdomain (overrides env var)
- **`pnpm check-subdomain <subdomain>`**: Check if subdomain is available

### Priority Order

1. **Command line argument** (highest priority)
2. **TUNNEL_SUBDOMAIN environment variable**
3. **DISCORD_AUTH_SUBDOMAIN config file**
4. **Random subdomain** (lowest priority)

## 🔧 How It Works

1. **Local Development Server**: Next.js runs on `localhost:3000` with full logging
2. **Local Tunnel**: Creates a public HTTPS URL using localtunnel
3. **Stable Subdomain**: Uses your configured subdomain for consistency
4. **OAuth Proxy**: Better-auth handles the OAuth flow through the tunnel

## 🛠️ Troubleshooting

### Subdomain Already Taken
If you get a "subdomain already taken" error:
1. Change `DISCORD_AUTH_SUBDOMAIN` in the config file
2. Restart the tunnel

### Tunnel Connection Issues
- Check your internet connection
- Try a different subdomain
- Ensure port 3000 is available

### Discord OAuth Errors
- Verify the callback URL in Discord Developer Portal
- Check that your environment variables are set correctly
- Ensure the tunnel URL is accessible

## 📚 Related Files

- `scripts/discord-auth-tunnel.sh` - Main tunnel script
- `scripts/discord-auth-config.sh` - Configuration file
- `packages/auth/src/index.ts` - Auth configuration
- `apps/nextjs/src/auth/server.ts` - Auth server setup