#!/bin/bash

# Discord Auth Tunnel Configuration
# Edit this file to customize your tunnel settings

# Stable subdomain for Discord OAuth callback
# This should be unique and not conflict with other users
# Example: "my-app-discord-auth-2024"
export DISCORD_AUTH_SUBDOMAIN="your-app-discord-auth"

# Local port for the Next.js development server
export DEV_PORT="3000"

# Tunnel service (local or ngrok)
export TUNNEL_SERVICE="local"

# Optional: Custom tunnel URL (if you want to use a specific URL)
# Leave empty to use the subdomain approach
export CUSTOM_TUNNEL_URL=""

# Optional: Discord OAuth app settings
# These are just for reference - you'll need to configure these in Discord Developer Portal
export DISCORD_CLIENT_ID="your-discord-client-id"
export DISCORD_CLIENT_SECRET="your-discord-client-secret"

# Instructions for Discord OAuth setup:
# 1. Go to https://discord.com/developers/applications
# 2. Create a new application or select existing one
# 3. Go to OAuth2 -> General
# 4. Add redirect URL: https://${DISCORD_AUTH_SUBDOMAIN}.loca.lt/api/auth/callback/discord
# 5. Copy Client ID and Client Secret to your .env file