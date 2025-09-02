# 🚀 Fixed Deployment Instructions for FlashPeg

The deployment has been fixed! Follow these steps:

## Option 1: Deploy via Render Dashboard (Most Reliable)

1. Go to https://dashboard.render.com/
2. Click "New +" → "Blueprint"
3. Connect your GitHub account if not already connected
4. Search for and select the `FlashPeg` repository
5. Click "Apply" to deploy using the fixed `render.yaml`
6. Wait for deployment to complete (2-3 minutes)

## Option 2: Deploy to Render Button

Click here: [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/mmaier88/FlashPeg)

## Option 3: Fork and Deploy

1. Fork the repository: https://github.com/mmaier88/FlashPeg
2. Go to Render Dashboard
3. Create new Blueprint from your forked repo
4. Deploy will use the fixed `render.yaml` automatically

## What Was Fixed

✅ Removed invalid `repo` and `branch` fields from render.yaml
✅ Simplified configuration to minimal working setup
✅ Added `plan: free` for explicit free tier
✅ Tested Flask app locally - confirmed working

## After Deployment

Your app will be available at:
- URL: `https://flashpeg-arbitrage.onrender.com`
- Health check: `https://flashpeg-arbitrage.onrender.com/health`

## To Verify Deployment

```bash
# Test if deployed
curl https://flashpeg-arbitrage.onrender.com/

# Check health
curl https://flashpeg-arbitrage.onrender.com/health
```

## If Still Having Issues

1. Check Render Dashboard logs for specific errors
2. Make sure you're using the latest version from GitHub
3. Try deploying with Blueprint (Option 1) as it's most reliable

The deployment should work now with the fixed configuration!