#!/bin/bash

# T3 Turbo Deployment Utils
# Common functions used across deployment scripts

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

# Load environment variables
load_env() {
    if [ -f .env ]; then
        echo -e "${BLUE}ℹ️ Loading environment variables...${NC}"
        # Safer way to load environment variables
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ $line =~ ^[[:space:]]*# ]] && continue
            [[ -z $line ]] && continue
            
            # Export the variable safely
            export "$line"
        done < .env
    else
        echo -e "${YELLOW}⚠️ .env file not found, using environment variables${NC}"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a service is running on a port
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

# Get current timestamp
get_timestamp() {
    date +%s
}

# Calculate duration between timestamps
calculate_duration() {
    local start_time=$1
    local end_time=$2
    echo $((end_time - start_time))
}

# Log metrics to file
log_metrics() {
    local log_file=$1
    local type=$2
    local duration=$3
    local status=$4
    
    echo "Date: $(date)" >> "$log_file"
    echo "Type: $type" >> "$log_file"
    echo "Duration: $duration seconds" >> "$log_file"
    echo "Status: $status" >> "$log_file"
    echo "---" >> "$log_file"
}

# Show recent metrics
show_recent_metrics() {
    local log_file=$1
    local lines=${2:-5}
    
    if [ -f "$log_file" ]; then
        echo "Recent entries:"
        tail -$lines "$log_file"
        
        # Calculate average time if file has content
        if [ -s "$log_file" ]; then
            local avg_time=$(grep "Duration:" "$log_file" | awk '{sum+=$2} END {print sum/NR}')
            log_info "Average duration: ${avg_time} seconds"
        fi
    else
        log_warning "No metrics found"
    fi
}

# Check if user is logged in to a service
check_service_auth() {
    local service=$1
    local check_command=$2
    local auth_message=$3
    
    if ! eval "$check_command" &> /dev/null; then
        log_warning "Not authenticated with $service"
        echo -e "${BLUE}📋 Authentication Options:${NC}"
        echo "$auth_message"
        return 1
    fi
    log_success "Authenticated with $service"
    return 0
}

# Start background process and return PID
start_background_process() {
    local command=$1
    local process_name=${2:-"Background process"}
    
    log_step "Starting $process_name..."
    eval "$command" &
    local pid=$!
    log_success "$process_name started (PID: $pid)"
    echo $pid
}

# Stop background process
stop_background_process() {
    local pid=$1
    local process_name=${2:-"Background process"}
    
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        log_success "$process_name stopped (PID: $pid)"
    fi
}

# Wait for service to be ready
wait_for_service() {
    local port=$1
    local service_name=${2:-"Service"}
    local max_attempts=${3:-30}
    local delay=${4:-2}
    
    log_step "Waiting for $service_name to be ready..."
    
    for i in $(seq 1 $max_attempts); do
        if check_port "$port" "$service_name" > /dev/null 2>&1; then
            log_success "$service_name is ready!"
            return 0
        fi
        
        if [ $i -lt $max_attempts ]; then
            echo -n "."
            sleep $delay
        fi
    done
    
    log_error "$service_name failed to start after $((max_attempts * delay)) seconds"
    return 1
}

# Show usage with common format
show_usage() {
    local script_name=$1
    local description=$2
    local commands=$3
    local prerequisites=$4
    
    echo -e "${BLUE}$script_name${NC}"
    echo ""
    echo "$description"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "$commands"
    echo ""
    
    if [ -n "$prerequisites" ]; then
        echo "Prerequisites:"
        echo "$prerequisites"
        echo ""
    fi
}

# Validate required environment variables
validate_env_vars() {
    local required_vars=("$@")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        return 1
    fi
    
    return 0
}

# Show deployment status summary
show_deployment_summary() {
    local web_status=$1
    local mobile_status=$2
    
    echo -e "${BLUE}📊 Deployment Summary${NC}"
    echo ""
    
    if [ "$web_status" = "running" ]; then
        log_success "Web: Development server running"
    else
        log_error "Web: Development server not running"
    fi
    
    if [ "$mobile_status" = "running" ]; then
        log_success "Mobile: Development server running"
    else
        log_error "Mobile: Development server not running"
    fi
    
    echo ""
}

# Cleanup function for background processes
cleanup_background_processes() {
    local pids=("$@")
    
    for pid in "${pids[@]}"; do
        if [ -n "$pid" ]; then
            stop_background_process "$pid"
        fi
    done
}

# Note: Functions are available when sourced, no need to export