#!/bin/bash

echo "Testing Docker deployment locally..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Create test environment file
cat > .env.test << EOF
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/demo
KEEPER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ARB_STETH_CONTRACT=0x0000000000000000000000000000000000000001
ARB_DAI_CONTRACT=0x0000000000000000000000000000000000000002
EOF

# Build Docker image
echo "Building Docker image..."
docker build -t flashpeg-keeper .

if [ $? -ne 0 ]; then
    echo "Docker build failed!"
    exit 1
fi

echo "Docker build successful!"

# Run container in test mode
echo "Starting container..."
docker run -d \
    --name flashpeg-test \
    -p 3000:3000 \
    --env-file .env.test \
    flashpeg-keeper

# Wait for container to start
echo "Waiting for container to start..."
sleep 5

# Test health endpoint
echo "Testing health endpoint..."
curl -f http://localhost:3000/health

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker test successful! Health check passed."
else
    echo "❌ Health check failed!"
    docker logs flashpeg-test
fi

# Show logs
echo ""
echo "Container logs:"
docker logs flashpeg-test

# Cleanup
echo ""
echo "Cleaning up..."
docker stop flashpeg-test
docker rm flashpeg-test
rm .env.test

echo "Test complete!"