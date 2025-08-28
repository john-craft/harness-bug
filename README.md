# CI Build Failure Reproduction

This repository is a **diagnostic setup** created to isolate and reproduce a reported CI bug outside of the CI environment.
The goal is to test whether a `docker build` failure seen in a customer’s CI pipeline can be reproduced locally by running the same build inside a **Docker-in-Docker (dind)** container image.

By following the steps in this README, you can reproduce the workflow locally. In our testing, the local reproduction **works successfully**, which strongly suggests the root cause lies in a **discrepancy between the CI environment and local setup** (e.g., storage drivers, resource constraints, registry issues).

---

## Quick Start

Run the automated reproduction script:

```bash
./run-reproduction.sh
```

This script will:

1. Set up a Docker 28 dind container
2. Copy test files (Dockerfile, reproduce-build.sh)
3. Run a simplified version of the customer's build process
4. Test tar export functionality
5. Clean up automatically

If you are using **private images**, you’ll need to set up authentication (see below).

---

## Authentication Setup (for Private Images)

The test `Dockerfile` uses a private base image:
`demonstrationorg/dhi-node:24-alpine3.22`

To reproduce with private images:

1. **Create Docker Hub Personal Access Token**

   * Go to Docker Hub → Account Settings → Security
   * Create a new Access Token with read permissions
   * Copy the token for use as password

2. **Create `.env` file**:

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

---

## Customer Issue Context

The customer’s CI pipeline fails when running `docker build` with this error:

```
ERROR: rpc error: code = Unknown desc = Error processing tar file(exit status 1): archive/tar: invalid tar header
```

### CI Environment Details

* **CI Pipeline (Failing)**: Docker Engine 28
* **CI Container**: `registry.com/v-docker/docker/docker:dind` (from `harness-workflow.yaml`)
* **Build Script**: `step-basic.sh`

### Customer's CI Build Command

```bash
docker build $dockerfilepath -t myimage:<+codebase.tag> -t $imagetagname:<+codebase.tag> \
    --build-arg=NUGET_PASSWORD=<+secrets.getValue('account.Harness_JfrogRW')> \
    --build-arg=VERSION=<+codebase.tag> \
    --build-arg=NUGET_URL=https://registry/v-nuget/index.json \
    --build-arg=NUGET_USERNAME=<+secrets.getValue('account.Harness_Jfrog_RW_User')> \
    ${DockerBuildArgs}
```

---

## Investigation Results

### Test Results

✅ **Docker 28 dind (Public Images)**: tar export works (docker save/load)
✅ **Docker 28 dind (Private Images)**: build/export of `demonstrationorg/dhi-node:24-alpine3.22` successful
❌ **Customer’s CI Pipeline**: fails with “invalid tar header”

### Key Findings

* `docker build` works correctly in Docker 28.3.3 dind locally
* The customer’s private image builds successfully in our reproduction
* **No "invalid tar header" errors** were observed locally
* Likely CI-specific causes:

  * Docker Engine patch version mismatch
  * Storage driver differences (`overlay2`, `devicemapper`)
  * Resource constraints (memory/disk/I/O)
  * Registry layer corruption or timing issues
  * Build context size or file permissions

---

## Files in This Repository

* `Dockerfile` — Test Dockerfile using private DHI image
* `reproduce-build.sh` — Simplified reproduction of `step-basic.sh`
* `run-reproduction.sh` — Automated test runner
* `step-basic.sh` — Customer’s original CI build script
* `harness-workflow.yaml` — Customer’s CI config reference
