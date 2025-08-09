#!/bin/bash

# Simple T3 Turbo Deployment Utils
# Basic functions without complex operations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Simple logging functions
log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

log_deploy() {
    echo -e "${CYAN}🚀 $1${NC}"
}

# Simple timestamp function
get_timestamp() {
    date +%s
}

# Simple duration calculation
calculate_duration() {
    local start_time=$1
    local end_time=$2
    echo $((end_time - start_time))
}

# Simple port check
check_port() {
    local port=$1
    local service_name=${2:-"Service"}
    
    if curl -s "http://localhost:$port" > /dev/null 2>&1; then
        log_success "$service_name: http://localhost:$port"
        return 0
    else
        log_error "$service_name: Not running"
        return 1
    fi
}

# Simple metrics logging
log_metrics() {
    local log_file=$1
    local service=$2
    local duration=$3
    local status=$4
    
    echo "Date: $(date)" >> "$log_file"
    echo "Service: $service" >> "$log_file"
    echo "Duration: $duration seconds" >> "$log_file"
    echo "Status: $status" >> "$log_file"
    echo "---" >> "$log_file"
}