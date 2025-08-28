# CI Build Failure Reproduction

This repository is a diagnostic setup created to isolate and reproduce the reported CI bug outside of the CI environment. The goal is to test whether a `docker build` failure seen in a customer’s CI pipeline can be reproduced locally by running the same build inside a **Docker-in-Docker (dind)** container image. The CI error is below.

```bash
ERROR: rpc error: code = Unknown desc = Error processing tar file(exit status 1): archive/tar: invalid tar header
```

## How to test locally

A script can be used to simulate the CI pipeline locally:

```bash
./run-reproduction.sh
```

This script will:

1. Set up a Docker 28 dind container
2. Copy test files (Dockerfile, `reproduce-build.sh`)
3. Run a simplified version of the customer's build process
4. Test tar export functionality
5. Clean up automatically

If you are using **private images**, you’ll need to set up authentication (see below).

## Authentication needed for private image repositories

The test `Dockerfile` uses a private base image, `demonstrationorg/dhi-node:24-alpine3.22`. The simulated pipeline needs authentication credentials to access private image repositories.

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

### CI Environment Details

* **CI Pipeline (Failing)**: Docker Engine 28
* **CI Container**: `registry.com/v-docker/docker/docker:dind` (from `harness-workflow.yaml`)
* **Build Script**: `step-basic.sh`

### Customer's CI Build Command

The command below is what is failing in the customer's CI pipeline.

```bash
docker build $dockerfilepath -t myimage:<+codebase.tag> -t $imagetagname:<+codebase.tag> \
    --build-arg=NUGET_PASSWORD=<+secrets.getValue('account.Harness_JfrogRW')> \
    --build-arg=VERSION=<+codebase.tag> \
    --build-arg=NUGET_URL=https://registry/v-nuget/index.json \
    --build-arg=NUGET_USERNAME=<+secrets.getValue('account.Harness_Jfrog_RW_User')> \
    ${DockerBuildArgs}
```

### Key Findings

* `docker build` works correctly in Docker 28.3.3 `dind` locally
* Likely CI-specific causes:

  * Docker Engine patch version mismatch
  * Storage driver differences (`overlay2`, `devicemapper`)
  * Resource constraints (memory/disk/I/O)
  * Private registry layer corruption or timing issues
  * Build context size or file permissions

## Files in This Repository

* `Dockerfile` — Test Dockerfile using private DHI image
* `reproduce-build.sh` — Simplified reproduction of `step-basic.sh`
* `run-reproduction.sh` — Automated test runner
* `step-basic.sh` — Customer’s original CI build script
* `harness-workflow.yaml` — Customer’s CI config reference
