#!/bin/bash

# Check if a localtunnel subdomain is available
# Usage: ./scripts/check-subdomain.sh your-subdomain-name

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

if [ -z "$1" ]; then
    log_error "Please provide a subdomain name"
    echo "Usage: $0 <subdomain-name>"
    echo "Example: $0 my-app-name"
    exit 1
fi

SUBDOMAIN=$1
TUNNEL_URL="https://${SUBDOMAIN}.loca.lt"

log_info "Checking if subdomain '$SUBDOMAIN' is available..."

# Try to start a temporary tunnel to check availability
log_info "Testing subdomain availability..."

# Start a temporary tunnel on a random port
RANDOM_PORT=$((3000 + RANDOM % 1000))
lt --port $RANDOM_PORT --subdomain $SUBDOMAIN > /tmp/subdomain-test.log 2>&1 &
TEMP_PID=$!

# Wait a moment for tunnel to start
sleep 3

# Check if tunnel started successfully
if curl -s "$TUNNEL_URL" > /dev/null 2>&1; then
    log_success "✅ Subdomain '$SUBDOMAIN' is AVAILABLE!"
    log_info "Your Discord OAuth callback URL will be:"
    log_info "   $TUNNEL_URL/api/auth/callback/discord"
    
    # Kill the temporary tunnel
    kill $TEMP_PID 2>/dev/null || true
    
    log_info ""
    log_info "To use this subdomain, update your config:"
    log_info "   export DISCORD_AUTH_SUBDOMAIN=\"$SUBDOMAIN\""
    log_info "   in scripts/discord-auth-config.sh"
else
    # Check if it failed due to subdomain already in use
    if grep -q "subdomain.*already taken" /tmp/subdomain-test.log 2>/dev/null; then
        log_error "❌ Subdomain '$SUBDOMAIN' is already TAKEN"
        log_info "Try a different subdomain name"
    else
        log_warning "⚠️ Could not verify subdomain availability"
        log_info "You can still try using it, but it might be taken"
    fi
    
    # Kill the temporary tunnel
    kill $TEMP_PID 2>/dev/null || true
fi

# Clean up
rm -f /tmp/subdomain-test.log