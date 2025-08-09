# 🚀 T3 Turbo Deployment Guide

## 🌐 **Your Public URL is Ready!**

**🔗 Live Demo: [Your ngrok URL will be displayed when you start ngrok]**

The ngrok URL is accessible from anywhere on the internet and will work as long as the development server is running.

---

## 📋 Current Status

✅ **Webapp**: Running and accessible  
✅ **Frontend**: Fully functional with React 19 + Next.js 15  
✅ **Styling**: Tailwind CSS working  
✅ **Theme**: Dark/light mode toggle  
✅ **Forms**: Post creation form (UI only)  
✅ **Ngrok Tunnel**: Authenticated and stable  
✅ **Vercel Production**: Deployed and live  
⚠️ **Database**: Not connected (needs real PostgreSQL)  
⚠️ **Auth**: Discord OAuth (needs real credentials)  

---

## 🎯 What You Can Test Right Now

1. **Visit the homepage**: See the beautiful T3 Turbo interface
2. **Theme switching**: Click the sun/moon icon in bottom right
3. **Responsive design**: Resize your browser window
4. **Form interactions**: Try the post creation form
5. **Authentication UI**: See the Discord sign-in button
6. **Ngrok monitoring**: Visit http://localhost:4040 for request logs

---

## 🚀 Vercel Production Deployment (Recommended)

### Prerequisites
1. **Vercel Account**: Sign up at [vercel.com](https://vercel.com)
2. **Vercel CLI**: Install with `npm install -g vercel`
3. **Vercel Token**: Get from [vercel.com/account/tokens](https://vercel.com/account/tokens)

### Deployment Process with Timing Metrics

```bash
# Start timing the deployment
start_time=$(date +%s)

# Deploy to Vercel with token (non-interactive)
vercel --token YOUR_VERCEL_TOKEN --yes --prod 2>&1 | tee deployment.log

# Calculate deployment time
end_time=$(date +%s)
deployment_time=$((end_time - start_time))

echo "Deployment completed in ${deployment_time} seconds"
echo "Deployment time: ${deployment_time}s" >> deployment.log
```

### Expected Deployment Times

| Stage | Expected Time | Notes |
|-------|---------------|-------|
| **First Deployment** | 2-5 minutes | Includes dependency installation |
| **Subsequent Deployments** | 30-90 seconds | Uses build cache |
| **Dependency Installation** | 15-30 seconds | pnpm install |
| **Build Process** | 30-60 seconds | Next.js build |
| **File Upload** | 10-30 seconds | 143+ files |
| **CDN Distribution** | 10-30 seconds | Global propagation |

### Deployment Logging and Monitoring

#### 1. **Log Deployment Metrics**
```bash
# Create a deployment tracking script
cat > deploy-with-metrics.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Vercel deployment..."
start_time=$(date +%s)

# Deploy and capture all output
vercel --token $VERCEL_TOKEN --yes --prod 2>&1 | tee "deployment-$(date +%Y%m%d-%H%M%S).log"

# Calculate timing
end_time=$(date +%s)
deployment_time=$((end_time - start_time))

# Log metrics
echo "📊 Deployment Metrics:" | tee -a deployment-metrics.log
echo "Date: $(date)" | tee -a deployment-metrics.log
echo "Duration: ${deployment_time} seconds" | tee -a deployment-metrics.log
echo "Status: $([ $? -eq 0 ] && echo 'SUCCESS' || echo 'FAILED')" | tee -a deployment-metrics.log
echo "---" | tee -a deployment-metrics.log

# Performance analysis
if [ $deployment_time -lt 60 ]; then
    echo "✅ Fast deployment (< 1 minute)"
elif [ $deployment_time -lt 180 ]; then
    echo "⚠️ Normal deployment (1-3 minutes)"
else
    echo "🐌 Slow deployment (> 3 minutes) - check logs"
fi
EOF

chmod +x deploy-with-metrics.sh
```

#### 2. **Monitor Deployment Performance**
```bash
# View deployment history
cat deployment-metrics.log

# Check if deployment times are improving
tail -10 deployment-metrics.log | grep "Duration:"

# Analyze deployment patterns
grep "Duration:" deployment-metrics.log | awk '{print $2}' | sort -n
```

#### 3. **Troubleshoot Slow Deployments**
```bash
# Check what's taking time
grep -E "(Installing|Building|Uploading|Deploying)" deployment-*.log

# Compare deployment times
echo "Average deployment time: $(grep "Duration:" deployment-metrics.log | awk '{sum+=$2} END {print sum/NR}') seconds"
```

### Vercel Configuration

#### 1. **Environment Variables**
Set these in Vercel dashboard or via CLI:
```bash
# Set environment variables
vercel env add POSTGRES_URL
vercel env add AUTH_SECRET
vercel env add AUTH_DISCORD_ID
vercel env add AUTH_DISCORD_SECRET
```

#### 2. **Custom Domain (Optional)**
```bash
# Add custom domain
vercel domains add yourdomain.com
```

### Deployment Commands

#### **Quick Deploy (with timing)**
```bash
time vercel --token $VERCEL_TOKEN --yes --prod
```

#### **Deploy with Environment Variables**
```bash
vercel --token $VERCEL_TOKEN --yes --prod \
  -e POSTGRES_URL="your-db-url" \
  -e AUTH_SECRET="your-secret"
```

#### **Force Redeploy**
```bash
vercel --token $VERCEL_TOKEN --yes --prod --force
```

### Performance Optimization

#### **Build Cache**
- Vercel automatically caches dependencies
- Subsequent deployments are much faster
- Cache is invalidated when `package.json` changes

#### **Bundle Analysis**
```bash
# Analyze bundle size
vercel build
# Check .next/analyze/ for bundle reports
```

#### **Monitoring**
- **Vercel Dashboard**: Real-time deployment status
- **Function Logs**: Serverless function performance
- **Analytics**: Page load times and user metrics

---

## 🔧 Ngrok Setup (Development Method)

### Prerequisites
1. **Ngrok Account**: Sign up at [ngrok.com](https://ngrok.com)
2. **Authtoken**: Get your authtoken from [dashboard.ngrok.com](https://dashboard.ngrok.com/get-started/your-authtoken)

### Installation & Configuration

```bash
# Install ngrok (if not already installed)
curl -L https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Configure ngrok with your authtoken
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE

# Start the tunnel
ngrok http 3000
```

### Getting Your Public URL
When you start ngrok, it will display your public URL in the terminal output. The URL will look like:
```
https://[random-string].ngrok-free.app
```

### Ngrok Features
- **Public HTTPS URL**: Automatically generated (changes on restart)
- **Web Interface**: Monitor traffic at http://localhost:4040
- **Request Inspection**: Real-time request/response logs
- **Stable Connection**: More reliable than other tunnel services
- **Custom Domains**: Available with paid plans

### Important Notes
- **URL Changes**: The ngrok URL changes each time you restart ngrok
- **Session Timeout**: Free tunnels close after 8 hours of inactivity
- **Keep Process Running**: Don't close the ngrok terminal to maintain the tunnel

---

## 🔧 Alternative Deployment Options

### Option 1: Netlify (Free)

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Deploy
netlify deploy --prod --dir=apps/nextjs/.next
```

### Option 2: Railway (Free tier)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Deploy
railway up
```

### Option 3: Render (Free tier)

1. Connect your GitHub repository
2. Select "Web Service"
3. Set build command: `cd apps/nextjs && pnpm build`
4. Set start command: `cd apps/nextjs && pnpm start`

---

## 🗄️ Database Setup (Optional)

To get full functionality, you'll need a PostgreSQL database:

### Option A: Supabase (Free tier)
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Get your connection string
4. Update `.env` file:

```env
POSTGRES_URL="postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres"
```

### Option B: Neon (Free tier)
1. Go to [neon.tech](https://neon.tech)
2. Create a new project
3. Get your connection string
4. Update `.env` file

### Option C: Railway PostgreSQL
1. Create a new PostgreSQL service on Railway
2. Get the connection string
3. Update `.env` file

---

## 🔐 Authentication Setup (Optional)

To enable Discord OAuth:

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application
3. Go to OAuth2 settings
4. Add redirect URI: `https://your-domain.com/api/auth/callback/discord`
5. Update `.env` file:

```env
AUTH_DISCORD_ID="your-discord-client-id"
AUTH_DISCORD_SECRET="your-discord-client-secret"
AUTH_SECRET="your-random-secret-key"
```

---

## 📱 Mobile App Deployment

The Expo mobile app is in `apps/expo/`. To deploy:

```bash
# Install EAS CLI
npm install -g eas-cli

# Login to Expo
eas login

# Configure the app
cd apps/expo
eas build:configure

# Build for production
eas build --platform all --profile production
```

---

## 🧪 Testing Your Deployment

### Automated Testing
```bash
# Run all tests
pnpm test

# Run type checking
pnpm typecheck

# Run linting
pnpm lint
```

### Manual Testing Checklist
- [ ] Homepage loads correctly
- [ ] Theme toggle works
- [ ] Responsive design on mobile
- [ ] Form interactions work
- [ ] Authentication flow (if configured)
- [ ] Database operations (if configured)
- [ ] Ngrok tunnel is stable (dev)
- [ ] Ngrok web interface accessible (dev)
- [ ] Vercel deployment is live (prod)
- [ ] Vercel dashboard shows success (prod)

---

## 🆘 Troubleshooting

### Common Issues:

1. **Build fails**: Check Node.js version (requires 22.14.0+)
2. **Database errors**: Ensure PostgreSQL connection string is correct
3. **Auth errors**: Verify Discord OAuth credentials
4. **Port conflicts**: Change port in `apps/nextjs/package.json`
5. **Ngrok auth fails**: Verify authtoken is correct and valid
6. **Ngrok URL changes**: Restart ngrok to get a new URL
7. **Vercel deployment slow**: Check build cache and dependencies
8. **Vercel build fails**: Check environment variables and build logs

### Performance Issues:

#### **Slow Vercel Deployments**
```bash
# Check deployment logs
cat deployment-*.log | grep -E "(Installing|Building|Uploading)"

# Analyze timing
grep "Duration:" deployment-metrics.log | tail -5

# Force rebuild if needed
vercel --token $VERCEL_TOKEN --yes --prod --force
```

#### **Large Bundle Sizes**
```bash
# Analyze bundle
vercel build
# Check .next/analyze/ for optimization opportunities
```

### Getting Help:
- Check the [T3 Turbo documentation](https://github.com/t3-oss/create-t3-turbo)
- Review the [Next.js docs](https://nextjs.org/docs)
- Check the [Expo docs](https://docs.expo.dev)
- Visit [ngrok docs](https://ngrok.com/docs) for tunnel issues
- Visit [Vercel docs](https://vercel.com/docs) for deployment issues

---

## 🎉 Success!

Your T3 Turbo webapp is now live and testable! 

### Development:
- **Ngrok URL**: Displayed when you start ngrok (changes on restart)
- **Local Development**: http://localhost:3000

### Production:
- **Vercel URL**: Permanent and stable
- **Global CDN**: Fast performance worldwide
- **Automatic HTTPS**: Secure by default

For a permanent deployment, Vercel is recommended for its speed, reliability, and global distribution.