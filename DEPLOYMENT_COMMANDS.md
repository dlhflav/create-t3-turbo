# 🚀 T3 Turbo Deployment Commands

## 📋 Streamlined Command Overview

### **🎯 Recommended: Use Main Deployment Script**
```bash
./scripts/deploy.sh [COMMAND]
```

## 🖥️ **Web Commands**

### Development
```bash
./scripts/deploy.sh web:dev        # Start web development server
./scripts/deploy.sh web:tunnel     # Start web dev + local tunnel (default)
./scripts/deploy.sh web:ngrok-tunnel # Start web dev + ngrok tunnel
```

### Production
```bash
./scripts/deploy.sh web:deploy  # Deploy web to Vercel
```

## 📱 **Mobile Commands**

### Development
```bash
./scripts/deploy.sh mobile:dev    # Start mobile development server
./scripts/deploy.sh mobile:tunnel # Start mobile dev + ngrok tunnel
```

### Building
```bash
./scripts/deploy.sh mobile:build  # Build mobile app (development)
./scripts/deploy.sh mobile:prod   # Build mobile app (production)
```

## 🚀 **Complete Deployments**

```bash
./scripts/deploy.sh all:web    # Complete web deployment (dev + tunnel + deploy)
./scripts/deploy.sh all:mobile # Complete mobile deployment (dev + tunnel + build)
```

## 🛑 **Stop Commands**

```bash
./scripts/deploy.sh stop:web      # Stop web development servers
./scripts/deploy.sh stop:mobile   # Stop mobile development servers
./scripts/deploy.sh stop:all      # Stop all development servers
```

## 🔧 **Utility Commands**

```bash
./scripts/deploy.sh status     # Show all services status
./scripts/deploy.sh help       # Show this help
```

---

## 📚 **Legacy Scripts (Removed)**

All legacy scripts have been removed and their functionality is now consolidated into the main `./scripts/deploy.sh` script.

---

## 🔑 **Environment Variables**

### **Required Tokens**
```bash
# .env file or environment variables
VERCEL_TOKEN=your_vercel_token_here
NGROK_TOKEN=your_ngrok_token_here
EXPO_TOKEN=your_expo_token_here  # Optional
```

### **Token Sources**
- **Vercel**: https://vercel.com/account/tokens
- **Ngrok**: https://ngrok.com/dashboard/your/authtokens
- **Expo**: https://expo.dev/accounts/[username]/settings/access-tokens

---

## 🎯 **Quick Start Examples**

### **Web Development with Tunnel**
```bash
./scripts/deploy.sh web:tunnel
# Starts web server + local tunnel (default)
# Access via: https://[random].loca.lt
# Password: Retrieved from https://loca.lt/mytunnelpassword

./scripts/deploy.sh web:ngrok-tunnel
# Starts web server + ngrok tunnel
# Access via: https://[random].ngrok-free.app
```

### **Mobile Development with Tunnel**
```bash
./scripts/deploy.sh mobile:tunnel
# Starts Expo server + ngrok tunnel
# Access via: https://[random].ngrok-free.app
```

### **Complete Web Deployment**
```bash
./scripts/deploy.sh all:web
# Starts web server + tunnel + deploys to Vercel
```

### **Check Status**
```bash
./scripts/deploy.sh status
# Shows all running services and tunnel URLs
```

### **Stop Services**
```bash
./scripts/deploy.sh stop:all
# Stops all development servers and tunnels
```

---

## 🔄 **Migration from Old Scripts**

### **Old → New**
```bash
# Old (Removed)
./scripts/deploy-legacy.sh tunnel
./scripts/mobile-ngrok.sh tunnel

# New (Streamlined)
./scripts/deploy.sh web:tunnel
./scripts/deploy.sh mobile:tunnel
```

### **Variable Name Changes**
```bash
# Old
NGROK_AUTHTOKEN=your_token

# New (Unified)
NGROK_TOKEN=your_token
```

---

## 🛠️ **Troubleshooting**

### **Common Issues**
1. **"Token not configured"**: Set tokens in `.env` file or environment
2. **"Port already in use"**: Stop other processes on ports 3000/8081
3. **"Ngrok authentication failed"**: Verify NGROK_TOKEN is correct

### **Quick Fixes**
```bash
# Check status
./scripts/deploy.sh status

# Kill all processes
pkill -f "expo\|ngrok\|next"

# Restart with tunnel
./scripts/deploy.sh mobile:tunnel
```

---

## ⚠️ **Important Tunnel Limitations**

### **🚫 Ngrok Tunnel Conflicts**
**Problem**: Cannot run web ngrok and Expo ngrok simultaneously
- **Web ngrok**: Uses global ngrok installation
- **Expo ngrok**: Uses its own ngrok process (`@expo/ngrok-bin`)
- **Result**: Only one tunnel can be active at a time

### **💳 Ngrok Premium Requirement**
**Problem**: Multiple tunnels require ngrok premium account
- **Free ngrok**: Limited to 1 tunnel at a time
- **Premium ngrok**: Required for multiple simultaneous tunnels
- **Workaround**: Use different tunnel types (ngrok + local tunnel)

### **🌐 Local Tunnel IP Instability**
**Problem**: Cursor agent IP changes frequently
- **Issue**: Password from `https://loca.lt/mytunnelpassword` becomes invalid
- **Cause**: IP address changes between deployments
- **Impact**: Cannot access local tunnel from mobile devices

### **📱 Mobile Browser Workaround Needed**
**Solution**: Find mobile browser with custom user agent
- **Goal**: Bypass local tunnel password prompt
- **Method**: Set specific user agent to avoid IP verification
- **Status**: Research needed for compatible mobile browsers

---

## 🔄 **Current Workarounds**

### **Single Tunnel Strategy**
```bash
# Option 1: Web tunnel only
./scripts/deploy.sh web:tunnel

# Option 2: Mobile tunnel only  
./scripts/deploy.sh mobile:tunnel

# Option 3: Web with local tunnel (default)
./scripts/deploy.sh web:tunnel  # Uses local tunnel by default
```

### **Tunnel Type Selection**
```bash
# Web with ngrok tunnel
./scripts/deploy.sh web:ngrok-tunnel

# Web with local tunnel (default)
./scripts/deploy.sh web:tunnel

# Mobile with Expo tunnel
./scripts/deploy.sh mobile:tunnel
```

### **Status Monitoring**
```bash
# Check current tunnel status
./scripts/deploy.sh status

# Shows:
# - Current IP address
# - Active tunnel URLs with PIDs
# - Local tunnel password (if applicable)
# - Ngrok tunnel URLs (if applicable)
# - Process PIDs and names for all running services
# - Recent tunnel output from web_tunnel_output.log
```

---

## 📊 **Current Status**

- ✅ **Main script**: `./scripts/deploy.sh`
- ✅ **Consistent variable names**: `NGROK_TOKEN`
- ✅ **Both web and mobile support**
- ✅ **Multiple tunnel types**: ngrok, local tunnel, Expo tunnel
- ✅ **Status monitoring with IP and password info**
- ✅ **Complete deployment workflows**
- ⚠️ **Tunnel limitation**: Only one tunnel active at a time
- 🔄 **Workaround**: Use different tunnel types for web/mobile

### **Available Tunnel Types**
- **Web ngrok**: `./scripts/deploy.sh web:ngrok-tunnel`
- **Web local tunnel**: `./scripts/deploy.sh web:tunnel` (default)
- **Mobile Expo tunnel**: `./scripts/deploy.sh mobile:tunnel`

**🎉 Recommendation: Use `./scripts/deploy.sh` for all deployments!**

**⚠️ Note**: Due to ngrok limitations, only one tunnel can be active at a time. Choose the tunnel type based on your current development needs.

---

## 📄 **Log Files**

The deployment script creates several log files for monitoring:

- **`web_output.log`** - Next.js development server output
- **`web_tunnel_output.log`** - Local tunnel and ngrok tunnel output
- **`mobile_output.log`** - Expo development server output

These logs are automatically cleaned when using the `clean` command or when starting new deployments.

## 🔢 **Process Information**

The status command displays Process IDs (PIDs) and names for all running services:

- **Individual PIDs**: Shown next to each running service (e.g., "Web server: Running on http://localhost:3000 (PID: 12345)")
- **Ngrok URL**: Prominently displayed in the main status line (e.g., "Ngrok tunnel: https://example.ngrok-free.app (PID: 12345)")
- **Process Details**: Grouped PIDs with process names for all related processes:
  - **Web processes**: Next.js and Turbo processes (sh, node, turbo)
  - **Mobile processes**: Expo development server processes (npm, sh, node)
  - **Tunnel processes**: Local tunnel and ngrok processes (bash, ngrok, node)

This information is useful for debugging and manually killing specific processes if needed.