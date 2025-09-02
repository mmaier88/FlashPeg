#!/bin/bash

# FlashPeg One-Click Deployment Script
# This script automates the entire Render deployment process

set -e

echo "🚀 FlashPeg One-Click Deployment"
echo "================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() { echo -e "${BLUE}➤ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

# Check if Render CLI is installed
check_render_cli() {
    if ! command -v render &> /dev/null; then
        print_warning "Render CLI not installed. Installing..."
        
        # Install Render CLI based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew tap render-oss/render
                brew install render
            else
                print_error "Homebrew not found. Please install from https://brew.sh"
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            curl -fsSL https://cli.render.com/install | sh
        else
            print_error "Unsupported OS. Please install Render CLI manually from https://render.com/docs/cli"
            exit 1
        fi
        
        print_success "Render CLI installed!"
    else
        print_success "Render CLI found"
    fi
}

# Authenticate with Render
authenticate_render() {
    print_step "Checking Render authentication..."
    
    # Check if already authenticated
    if render auth whoami &> /dev/null; then
        RENDER_USER=$(render auth whoami)
        print_success "Already authenticated as: $RENDER_USER"
    else
        print_step "Please authenticate with Render..."
        echo ""
        echo "1. Go to: https://dashboard.render.com/account/api-keys"
        echo "2. Create a new API key"
        echo "3. Copy the key and paste it below"
        echo ""
        
        render auth login
        print_success "Authentication complete!"
    fi
}

# Deploy to Render
deploy_to_render() {
    print_step "Deploying FlashPeg to Render..."
    
    # Create the service
    print_step "Creating web service..."
    
    SERVICE_NAME="flashpeg-arbitrage-$(date +%s)"
    
    # Deploy using render.yaml
    render services create \
        --name "$SERVICE_NAME" \
        --type web \
        --runtime python \
        --repo "https://github.com/mmaier88/FlashPeg.git" \
        --branch main \
        --build-command "pip install -r requirements-flask.txt" \
        --start-command "gunicorn wsgi:app" \
        --health-check-path "/health" \
        --auto-deploy \
        --env PYTHON_VERSION=3.9
    
    print_success "Service created: $SERVICE_NAME"
    
    # Get service URL
    SERVICE_URL=$(render services list --format json | jq -r ".[] | select(.name==\"$SERVICE_NAME\") | .serviceDetails.url" 2>/dev/null || echo "")
    
    if [ -n "$SERVICE_URL" ]; then
        print_success "Service URL: $SERVICE_URL"
        echo ""
        echo "🎉 Deployment initiated!"
        echo "📊 Monitor deployment: https://dashboard.render.com/"
        echo "🌐 Your app will be available at: $SERVICE_URL"
        echo ""
    fi
}

# Main deployment flow
main() {
    echo "This script will:"
    echo "1. Install Render CLI (if needed)"
    echo "2. Authenticate with Render"
    echo "3. Deploy FlashPeg to Render"
    echo ""
    
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    print_step "Starting automated deployment..."
    
    check_render_cli
    authenticate_render
    deploy_to_render
    
    print_success "Deployment complete!"
    echo ""
    echo "🔗 Next steps:"
    echo "  1. Visit https://dashboard.render.com/ to monitor deployment"
    echo "  2. Add environment variables (RPC URL, private key) if needed"
    echo "  3. Wait for deployment to complete (~2-3 minutes)"
    echo "  4. Test your app at the provided URL"
    echo ""
    echo "💡 Need help? Check the deployment logs in Render dashboard."
}

# Handle script interruption
trap 'print_error "Deployment interrupted"; exit 130' INT

# Run main function
main "$@"