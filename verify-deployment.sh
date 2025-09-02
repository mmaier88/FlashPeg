#!/bin/bash

# FlashPeg Deployment Verification Script
# Checks if deployment is working correctly

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_step() { echo -e "${BLUE}➤ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

echo "🔍 FlashPeg Deployment Verification"
echo "===================================="
echo ""

# Get service URL
if [ -z "$1" ]; then
    read -p "Enter your Render service URL (e.g., https://your-app.onrender.com): " SERVICE_URL
else
    SERVICE_URL="$1"
fi

# Remove trailing slash
SERVICE_URL=${SERVICE_URL%/}

print_step "Testing deployment at: $SERVICE_URL"
echo ""

# Test 1: Basic connectivity
print_step "Test 1: Basic connectivity"
if curl -s --connect-timeout 10 "$SERVICE_URL/" > /dev/null; then
    print_success "App is reachable"
else
    print_error "App is not reachable"
    echo "  - Check if deployment completed"
    echo "  - Verify the URL is correct"
    exit 1
fi

# Test 2: Health check endpoint
print_step "Test 2: Health check"
HEALTH_RESPONSE=$(curl -s --connect-timeout 10 "$SERVICE_URL/health" || echo "FAILED")

if [[ "$HEALTH_RESPONSE" == *'"status":"healthy"'* ]]; then
    print_success "Health check passed"
else
    print_error "Health check failed"
    echo "  Response: $HEALTH_RESPONSE"
fi

# Test 3: Main endpoint JSON response
print_step "Test 3: Main endpoint"
MAIN_RESPONSE=$(curl -s --connect-timeout 10 "$SERVICE_URL/" || echo "FAILED")

if [[ "$MAIN_RESPONSE" == *'"status":"success"'* ]]; then
    print_success "Main endpoint working"
    
    # Extract and display key info
    echo ""
    echo "📊 Service Information:"
    
    if command -v jq &> /dev/null; then
        echo "$MAIN_RESPONSE" | jq -r '"  Python Version: " + .python_version'
        echo "$MAIN_RESPONSE" | jq -r '"  Port: " + (.environment.PORT // "unknown")'
        echo "$MAIN_RESPONSE" | jq -r '"  RPC Configured: " + (if .environment.has_rpc then "Yes" else "No" end)'
        echo "$MAIN_RESPONSE" | jq -r '"  Wallet Configured: " + (if .environment.has_key then "Yes" else "No" end)'
    else
        echo "  Response: $MAIN_RESPONSE"
    fi
else
    print_error "Main endpoint failed"
    echo "  Response: $MAIN_RESPONSE"
fi

# Test 4: Response time
print_step "Test 4: Response time"
RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null "$SERVICE_URL/" || echo "0")

if (( $(echo "$RESPONSE_TIME < 5.0" | bc -l) )); then
    print_success "Response time: ${RESPONSE_TIME}s (Good)"
elif (( $(echo "$RESPONSE_TIME < 10.0" | bc -l) )); then
    print_warning "Response time: ${RESPONSE_TIME}s (Acceptable)"
else
    print_error "Response time: ${RESPONSE_TIME}s (Slow)"
fi

# Test 5: Check for common issues
print_step "Test 5: Common issues check"

# Check if it's still starting up
if [[ "$MAIN_RESPONSE" == *"starting"* ]] || [[ "$MAIN_RESPONSE" == *"initializing"* ]]; then
    print_warning "App appears to still be starting up"
    echo "  Wait a few more minutes and try again"
fi

# Check for error messages
if [[ "$MAIN_RESPONSE" == *"error"* ]] || [[ "$MAIN_RESPONSE" == *"Error"* ]]; then
    print_warning "App reports errors in response"
    echo "  Check Render logs for details"
fi

echo ""
echo "🎯 Deployment Status Summary:"
echo "=============================="

# Overall status
if [[ "$HEALTH_RESPONSE" == *'"status":"healthy"'* ]] && [[ "$MAIN_RESPONSE" == *'"status":"success"'* ]]; then
    print_success "✅ Deployment is working correctly!"
    echo ""
    echo "🔗 Your FlashPeg app is live at: $SERVICE_URL"
    echo ""
    echo "🔧 Next steps:"
    echo "  1. Add your RPC URL and private key in Render dashboard"
    echo "  2. Deploy your smart contracts and add contract addresses"
    echo "  3. Monitor logs for arbitrage opportunities"
    echo ""
else
    print_warning "⚠️  Deployment has issues"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "  1. Check Render dashboard for deployment logs"
    echo "  2. Verify build completed successfully"
    echo "  3. Check for any error messages in logs"
    echo "  4. Wait a few minutes if still deploying"
    echo ""
fi

# Additional info
echo "💡 Useful URLs:"
echo "  App: $SERVICE_URL"
echo "  Health: $SERVICE_URL/health"
echo "  Dashboard: https://dashboard.render.com/"
echo ""