#!/bin/bash
# Automated reproduction environment for customer's Docker build issue
# This script sets up Docker 28 dind container and runs the reproduction test

set -e

echo "=== Docker Build Issue Reproduction Script ==="
echo "Setting up Docker 28 test environment for customer's tar export issue..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    print_status "Cleaning up containers..."
    docker rm -f dind-28 2>/dev/null || true
}

# Cleanup on exit
trap cleanup EXIT

print_status "Starting reproduction test..."

# Pull required image
print_status "Pulling Docker 28 dind image..."
docker pull docker:dind

# Start container
print_status "Starting Docker 28 dind container..."
docker run --privileged -d --name dind-28 docker:dind

# Wait for container to be ready
print_status "Waiting for container to initialize..."
sleep 10

# Check Docker version
print_status "Checking Docker version..."
docker exec dind-28 docker version --format 'Docker Engine: {{.Server.Version}}'

# Copy files to container
print_status "Copying test files to container..."
docker cp ./Dockerfile dind-28:/Dockerfile
docker cp ./reproduce-build.sh dind-28:/reproduce-build.sh
docker exec dind-28 chmod +x /reproduce-build.sh

# Authenticate with Docker Hub if credentials provided
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    print_status "Authenticating with Docker Hub..."
    if docker exec dind-28 docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD"; then
        print_success "Docker Hub authentication successful"
    else
        print_error "Docker Hub authentication failed"
        exit 1
    fi
else
    print_status "No Docker Hub credentials provided - using public images only"
fi

# Run reproduction test
print_status "Running Docker 28 reproduction test..."

if docker exec dind-28 sh /reproduce-build.sh; then
    print_success "Docker 28 test PASSED"
    
    # Check if tar file was created and is valid
    if docker exec dind-28 test -f /tmp/test-export.tar; then
        size=$(docker exec dind-28 ls -lh /tmp/test-export.tar | awk '{print $5}')
        print_success "Tar export successful ($size)"
        
        # Test tar integrity
        if docker exec dind-28 tar -tf /tmp/test-export.tar > /dev/null 2>&1; then
            print_success "Tar file integrity OK - no 'invalid tar header' error"
        else
            print_error "Tar file integrity FAILED - 'invalid tar header' error reproduced!"
            exit 1
        fi
    else
        print_error "Tar file not created"
        exit 1
    fi
else
    print_error "Docker 28 reproduction test FAILED"
    exit 1
fi

echo
print_status "=== Test Summary ==="
print_success "Docker 28 basic build and export test PASSED"
print_success "Reproduction environment ready for further testing!"