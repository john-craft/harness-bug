# Customer Issue Investigation

This document contains the investigation and reproduction setup for customer's Docker build failure in CI. The 
customer's CI pipeline fails when attempting to run `docker build`:
```
ERROR: rpc error: code = Unknown desc = Error processing tar file(exit status 1): archive/tar: invalid tar header
```

## Automated Reproduction Setup

### Authentication Setup
The Dockerfile now uses the private Docker Hub registry (`demonstrationorg/dhi-node:24-alpine3.22`). To reproduce with private images:

1. **Create Docker Hub Personal Access Token**:
   - Go to Docker Hub → Account Settings → Security
   - Create a new Access Token with read permissions
   - Copy the token for use as password

2. **Create .env file**:
```bash
cat > .env << EOF
DOCKER_USERNAME=your_dockerhub_username
DOCKER_PASSWORD=your_personal_access_token
EOF
```

3. **Run with Authentication**:
```bash
chmod +x run-reproduction.sh
source .env && DOCKER_USERNAME="$DOCKER_USERNAME" DOCKER_PASSWORD="$DOCKER_PASSWORD" ./run-reproduction.sh
```

### Quick Start (Public Images)
For testing without private registry access, use public images:
```bash
# Edit Dockerfile to use: FROM node:24-alpine3.22
./run-reproduction.sh
```

This script will:
1. Set up a Docker 28 dind container
2. Authenticate with Docker Hub (if credentials provided)
3. Copy test files (Dockerfile, reproduce-build.sh)
4. Run a simplified version of the customer's build process
5. Test tar export functionality
6. Clean up automatically

## Customer Environment Details
- **CI Pipeline (Failing)**: Docker Engine 28 
- **CI Container**: `registry.com/v-docker/docker/docker:dind` (from harness-workflow.yaml)
- **Build Script**: step-basic.sh with build configuration

## Customer's CI Build Process
The customer uses this docker build command from `step-basic.sh`:
```bash
docker build $dockerfilepath -t myimage:<+codebase.tag> -t $imagetagname:<+codebase.tag> \
    --build-arg=NUGET_PASSWORD=<+secrets.getValue('account.Harness_JfrogRW')> \
    --build-arg=VERSION=<+codebase.tag> \
    --build-arg=NUGET_URL=https://registry/v-nuget/index.json \
    --build-arg=NUGET_USERNAME=<+secrets.getValue('account.Harness_Jfrog_RW_User')> \
    ${DockerBuildArgs}
```

## Investigation Results

### Test Results Summary
✅ **Docker 28 dind (Public Images)**: Basic tar export successful (docker save/load works)  
✅ **Docker 28 dind (Private Images)**: Successfully built and exported `demonstrationorg/dhi-node:24-alpine3.22`  
❌ **Customer's CI Pipeline**: "invalid tar header" error during docker build  

### Key Findings
- Basic `docker build` works fine in Docker 28.3.3 dind environment
- Successfully reproduced customer's build process with their actual private base image
- **No "invalid tar header" errors** found in our reproduction environment
- Customer's error is likely specific to:
  - Specific Docker Engine patch version differences
  - Storage driver configuration (`overlay2`, `devicemapper`, etc.)
  - CI environment resource constraints (memory, disk, I/O)
  - Container registry layer corruption or timing issues
  - Build context size or file permission issues

### Files in This Repository
- `Dockerfile` - Test dockerfile using private DHI image
- `reproduce-build.sh` - Simplified reproduction script based on step-basic.sh
- `run-reproduction.sh` - Automated test runner for easy reproduction
- `step-basic.sh` - Customer's original CI build script
- `harness-workflow.yaml` - Customer's CI step to build image

## Next Steps for Further Investigation
To reproduce the actual customer issue, investigate:
1. **Buildx Configuration**: Test with customer's exact buildx builder setup
2. **Multi-platform Builds**: Test `--platform=$TARGETPLATFORM` scenarios
3. **Custom BuildKit**: Test with customer's BuildKit image and config
4. **Internal Images**: Test with images that require authentication
5. **CI Environment**: Test with exact CI environment variables and timing