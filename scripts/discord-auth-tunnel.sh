#!/bin/bash

# Discord Auth Development Tunnel Script
# This script starts the web server with a stable tunnel URL for Discord OAuth

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}🔧 $1${NC}"; }

# Load configuration
if [ -f "scripts/discord-auth-config.sh" ]; then
    source scripts/discord-auth-config.sh
else
    log_warning "Configuration file not found, using defaults"
    DISCORD_AUTH_SUBDOMAIN="your-app-discord-auth"
    DEV_PORT="3000"
    TUNNEL_SERVICE="local"
fi

# Check for TUNNEL_SUBDOMAIN environment variable first, then config file
if [ -n "$TUNNEL_SUBDOMAIN" ]; then
    STABLE_SUBDOMAIN="$TUNNEL_SUBDOMAIN"
    log_info "Using TUNNEL_SUBDOMAIN from environment: $STABLE_SUBDOMAIN"
elif [ -n "$DISCORD_AUTH_SUBDOMAIN" ]; then
    STABLE_SUBDOMAIN="$DISCORD_AUTH_SUBDOMAIN"
    log_info "Using DISCORD_AUTH_SUBDOMAIN from config: $STABLE_SUBDOMAIN"
else
    STABLE_SUBDOMAIN="your-app-discord-auth"
    log_warning "No subdomain configured, using default: $STABLE_SUBDOMAIN"
fi

log_step "Starting Discord Auth Development Tunnel..."

# Clean previous logs
rm -f web_output.log web_tunnel_output.log

# Start Next.js dev server
log_step "Starting Next.js development server..."
pnpm -F @acme/nextjs dev 2>&1 | tee web_output.log &
WEB_PID=$!
sleep 10

# Check if server is running
if curl -s http://localhost:${DEV_PORT} > /dev/null 2>&1; then
    log_success "Next.js server running on http://localhost:${DEV_PORT}"
    
    # Start local tunnel with stable subdomain
    log_step "Starting local tunnel with stable subdomain: $STABLE_SUBDOMAIN"
    
    # Install localtunnel if not already installed
    if ! command -v lt &> /dev/null; then
        log_step "Installing localtunnel..."
        npm install -g localtunnel
    fi
    
    # Check if subdomain is available before starting tunnel
    log_step "Checking if subdomain '$STABLE_SUBDOMAIN' is available..."
    
    # Start a temporary tunnel to test availability
    lt --port ${DEV_PORT} --subdomain $STABLE_SUBDOMAIN > /tmp/subdomain-test.log 2>&1 &
    TEMP_PID=$!
    sleep 3
    
    # Check if tunnel started successfully
    local tunnel_url="https://${STABLE_SUBDOMAIN}.loca.lt"
    if curl -s "$tunnel_url" > /dev/null 2>&1; then
        # Subdomain is available, kill the test tunnel
        kill $TEMP_PID 2>/dev/null || true
        rm -f /tmp/subdomain-test.log
        log_success "✅ Subdomain '$STABLE_SUBDOMAIN' is available"
        
        # Start the actual tunnel
        log_step "Starting tunnel with subdomain: $STABLE_SUBDOMAIN"
        lt --port ${DEV_PORT} --subdomain $STABLE_SUBDOMAIN 2>&1 | tee web_tunnel_output.log &
        TUNNEL_PID=$!
        sleep 5
    else
        # Check if it failed due to subdomain already in use
        if grep -q "subdomain.*already taken" /tmp/subdomain-test.log 2>/dev/null; then
            kill $TEMP_PID 2>/dev/null || true
            rm -f /tmp/subdomain-test.log
            log_error "❌ Subdomain '$STABLE_SUBDOMAIN' is already taken"
            log_info "Please change DISCORD_AUTH_SUBDOMAIN in scripts/discord-auth-config.sh"
            kill $WEB_PID 2>/dev/null || true
            return 1
        else
            # Other error, but we'll still try to use it
            kill $TEMP_PID 2>/dev/null || true
            rm -f /tmp/subdomain-test.log
            log_warning "⚠️ Could not verify subdomain availability, but will try to use it"
            
            # Start the actual tunnel
            log_step "Starting tunnel with subdomain: $STABLE_SUBDOMAIN"
            lt --port ${DEV_PORT} --subdomain $STABLE_SUBDOMAIN 2>&1 | tee web_tunnel_output.log &
            TUNNEL_PID=$!
            sleep 5
        fi
    fi
    
    # Get tunnel URL
    if [ -f web_tunnel_output.log ]; then
        TUNNEL_URL=$(grep -o 'https://[^[:space:]]*' web_tunnel_output.log | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            log_success "🎉 Discord Auth Development Tunnel Ready!"
            echo ""
            log_info "📱 Local Development: http://localhost:${DEV_PORT}"
            log_info "🌐 Public Tunnel URL: $TUNNEL_URL"
            echo ""
            log_info "🔗 Discord OAuth Callback URL:"
            log_info "   $TUNNEL_URL/api/auth/callback/discord"
            echo ""
            log_warning "⚠️  Add this URL to your Discord OAuth app settings:"
            log_warning "   $TUNNEL_URL/api/auth/callback/discord"
            echo ""
            log_info "📝 All development logs will appear in your console"
            log_info "🛑 Press Ctrl+C to stop both server and tunnel"
            echo ""
            
            # Wait for user to stop
            wait $WEB_PID $TUNNEL_PID
        else
            log_error "Failed to get tunnel URL"
            kill $WEB_PID 2>/dev/null || true
            return 1
        fi
    else
        log_error "Failed to start tunnel"
        kill $WEB_PID 2>/dev/null || true
        return 1
    fi
else
    log_error "Failed to start Next.js server"
    return 1
fi