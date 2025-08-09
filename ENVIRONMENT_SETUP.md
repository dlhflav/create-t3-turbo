# Environment Setup

This project includes an automated environment setup system that helps you configure your `.env` file by comparing it with `.env.example` and adding missing variables from your shell environment.

## Quick Setup

### Option 1: Using npm/pnpm script
```bash
pnpm setup:env
```

### Option 2: Using the deployment script
```bash
./scripts/deploy.sh setup:env
```

### Option 3: Running the script directly
```bash
./scripts/setup-env.sh
```

## What it does

The environment setup script performs the following steps:

1. **Checks for `.env.example`**: Ensures the example file exists
2. **Creates `.env` file**: If it doesn't exist, creates it from `.env.example`
3. **Compares variables**: Checks which variables from `.env.example` are missing in `.env`
4. **Adds from shell**: Adds missing variables from your shell environment (if available)
5. **Adds common tokens**: Automatically adds common deployment tokens:
   - `VERCEL_TOKEN` - For Vercel deployments
   - `NGROK_TOKEN` - For ngrok tunneling
   - `EXPO_TOKEN` - For Expo deployments
   - `AUTH_DISCORD_SECRET` - For Discord OAuth

## Automatic Integration

The environment setup is automatically run as part of the deployment process. When you run any deployment command (like `./scripts/deploy.sh web:dev`), it will:

1. Load existing environment variables
2. Run the environment setup to ensure all required variables are present
3. Proceed with the deployment

## Manual Configuration

If you prefer to set up your environment manually:

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and add your actual values:
   ```bash
   # Required variables
   POSTGRES_URL="your-database-url"
   AUTH_SECRET="your-auth-secret"
   AUTH_DISCORD_ID="your-discord-id"
   AUTH_DISCORD_SECRET="your-discord-secret"
   
   # Optional deployment tokens
   VERCEL_TOKEN="your-vercel-token"
   NGROK_TOKEN="your-ngrok-token"
   EXPO_TOKEN="your-expo-token"
   ```

## Environment Variables Reference

### Required Variables
- `POSTGRES_URL`: Your Supabase database connection string
- `AUTH_SECRET`: Secret for authentication (generate with `openssl rand -base64 32`)
- `AUTH_DISCORD_ID`: Discord OAuth application ID
- `AUTH_DISCORD_SECRET`: Discord OAuth application secret

### Optional Variables
- `VERCEL_TOKEN`: For deploying to Vercel
- `NGROK_TOKEN`: For creating ngrok tunnels
- `EXPO_TOKEN`: For Expo deployments

## Troubleshooting

### Missing Variables
If the script shows warnings about missing variables, you can:

1. Set them in your shell environment:
   ```bash
   export VARIABLE_NAME="value"
   ```

2. Add them manually to your `.env` file

3. Run the setup script again to pick up new environment variables

### Permission Issues
If you get permission errors, make sure the script is executable:
```bash
chmod +x scripts/setup-env.sh
```

### Script Not Found
If the deployment script can't find the setup script, ensure you're running from the project root directory.