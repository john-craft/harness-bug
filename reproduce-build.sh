#!/bin/bash
# Simplified reproduction script based on step-basic.sh
# This script mimics the customer's CI build process in a minimal way

set -e

echo "=== Starting Docker Build Reproduction ==="

# Set variables (simplified from CI template variables)
export imagetagname="testimage"
export dockerpath="."
export DockerBuildArgs=""

echo "Docker Build Arguments:"
echo "DockerPath: ${dockerpath}"
echo "DockerImageTag: ${imagetagname}:test"

# Wait for Docker to be ready (from step-basic.sh lines 25-29)
echo "Checking Docker availability..."
while ! docker ps > /dev/null 2>&1; do
    echo "Waiting for Docker to be ready..."
    sleep 1
done
echo "Docker is ready"

# Determine dockerfile path (from step-basic.sh lines 34-45)
if [[ -z "${dockerpath}" ]]; then
    echo "Using root folder for Dockerfile"
    export dockerfilepath="-f ./Dockerfile ."
elif [[ -f "${dockerpath}/dockerfile" ]]; then
    echo "Found dockerfile at ${dockerpath}/dockerfile"
    export dockerfilepath="-f ${dockerpath}/dockerfile ."
elif [[ -f "${dockerpath}/Dockerfile" ]]; then
    echo "Found Dockerfile at ${dockerpath}/Dockerfile"
    export dockerfilepath="-f ${dockerpath}/Dockerfile ."
else
    echo "No Dockerfile found, using default"
    export dockerfilepath="-f ./Dockerfile ."
fi

echo "=== Docker Build Command ==="
echo "docker build $dockerfilepath -t myimage:test -t $imagetagname:test --build-arg=VERSION=test ${DockerBuildArgs}"

# Execute the docker build (simplified from step-basic.sh line 51)
docker build $dockerfilepath -t myimage:test -t $imagetagname:test --build-arg=VERSION=test ${DockerBuildArgs}

echo "=== Listing Docker Images ==="
docker images

echo "=== Testing Image Export ==="
docker save myimage:test -o /tmp/test-export.tar
echo "Export successful, checking tar integrity..."
tar -tf /tmp/test-export.tar | head -5
echo "Tar file created: $(ls -lh /tmp/test-export.tar | awk '{print $5}')"

echo "=== Build and Export Complete ==="