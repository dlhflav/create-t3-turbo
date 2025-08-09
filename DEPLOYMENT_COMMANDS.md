# 🚀 T3 Turbo Deployment Commands

## 📋 Streamlined Command Overview

### **🎯 Recommended: Use Unified Script**
```bash
./scripts/deploy-unified.sh [COMMAND]
```

## 🖥️ **Web Commands**

### Development
```bash
./scripts/deploy-unified.sh web:dev     # Start web development server
./scripts/deploy-unified.sh web:tunnel  # Start web dev + ngrok tunnel
```

### Production
```bash
./scripts/deploy-unified.sh web:deploy  # Deploy web to Vercel
```

## 📱 **Mobile Commands**

### Development
```bash
./scripts/deploy-unified.sh mobile:dev    # Start mobile development server
./scripts/deploy-unified.sh mobile:tunnel # Start mobile dev + ngrok tunnel
```

### Building
```bash
./scripts/deploy-unified.sh mobile:build  # Build mobile app (development)
./scripts/deploy-unified.sh mobile:prod   # Build mobile app (production)
```

## 🚀 **Complete Deployments**

```bash
./scripts/deploy-unified.sh all:web    # Complete web deployment (dev + tunnel + deploy)
./scripts/deploy-unified.sh all:mobile # Complete mobile deployment (dev + tunnel + build)
```

## 🔧 **Utility Commands**

```bash
./scripts/deploy-unified.sh status     # Show all services status
./scripts/deploy-unified.sh help       # Show this help
```

---

## 📚 **Legacy Scripts (Still Available)**

### **Web Deployment**
```bash
./scripts/deploy.sh [COMMAND]          # Original web deploy script
./scripts/safe-deploy.sh [COMMAND]     # Safe version (no env export)
./scripts/deploy-all.sh [COMMAND]      # All-in-one script
```

### **Mobile Deployment**
```bash
./scripts/mobile-deploy.sh [COMMAND]   # Mobile-specific script
./scripts/mobile-ngrok.sh [COMMAND]    # Mobile ngrok script
```

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
./scripts/deploy-unified.sh web:tunnel
# Starts web server + ngrok tunnel
# Access via: https://[random].ngrok-free.app
```

### **Mobile Development with Tunnel**
```bash
./scripts/deploy-unified.sh mobile:tunnel
# Starts Expo server + ngrok tunnel
# Access via: https://[random].ngrok-free.app
```

### **Complete Web Deployment**
```bash
./scripts/deploy-unified.sh all:web
# Starts web server + tunnel + deploys to Vercel
```

### **Check Status**
```bash
./scripts/deploy-unified.sh status
# Shows all running services and tunnel URLs
```

---

## 🔄 **Migration from Old Scripts**

### **Old → New**
```bash
# Old
./scripts/deploy.sh tunnel
./scripts/mobile-ngrok.sh tunnel

# New (Unified)
./scripts/deploy-unified.sh web:tunnel
./scripts/deploy-unified.sh mobile:tunnel
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
./scripts/deploy-unified.sh status

# Kill all processes
pkill -f "expo\|ngrok\|next"

# Restart with tunnel
./scripts/deploy-unified.sh mobile:tunnel
```

---

## 📊 **Current Status**

- ✅ **Unified script**: `./scripts/deploy-unified.sh`
- ✅ **Consistent variable names**: `NGROK_TOKEN`
- ✅ **Both web and mobile support**
- ✅ **Ngrok tunneling for both platforms**
- ✅ **Status monitoring**
- ✅ **Complete deployment workflows**

**🎉 Recommendation: Use `./scripts/deploy-unified.sh` for all deployments!**