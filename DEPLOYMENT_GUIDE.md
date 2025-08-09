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

## 🔧 Ngrok Setup (Current Method)

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

### Option 1: Vercel (Recommended - Free)

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy from the project root
vercel --yes

# Or deploy just the Next.js app
cd apps/nextjs
vercel --yes
```

### Option 2: Netlify (Free)

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Deploy
netlify deploy --prod --dir=apps/nextjs/.next
```

### Option 3: Railway (Free tier)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Deploy
railway up
```

### Option 4: Render (Free tier)

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
- [ ] Ngrok tunnel is stable
- [ ] Ngrok web interface accessible

---

## 🆘 Troubleshooting

### Common Issues:

1. **Build fails**: Check Node.js version (requires 22.14.0+)
2. **Database errors**: Ensure PostgreSQL connection string is correct
3. **Auth errors**: Verify Discord OAuth credentials
4. **Port conflicts**: Change port in `apps/nextjs/package.json`
5. **Ngrok auth fails**: Verify authtoken is correct and valid
6. **Ngrok URL changes**: Restart ngrok to get a new URL

### Getting Help:
- Check the [T3 Turbo documentation](https://github.com/t3-oss/create-t3-turbo)
- Review the [Next.js docs](https://nextjs.org/docs)
- Check the [Expo docs](https://docs.expo.dev)
- Visit [ngrok docs](https://ngrok.com/docs) for tunnel issues

---

## 🎉 Success!

Your T3 Turbo webapp is now live and testable! The ngrok URL will be displayed when you start the tunnel and will work as long as the development server is running. For a permanent deployment, use one of the cloud platforms listed above.