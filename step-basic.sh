Traditional Docker build
chmod +x $(pwd)/Harness_CI/scripts/shared.sh
source Harness_CI/scripts/shared.sh
[ -z "${imagetagname}" ] && uaLog "Please make sure to set AppCi and ServiceName variables" "error" && exit 1;
[ -z "${DockerBuildArgs}" ] && uaLog "Please set docker build args to pass additional arguments" "error" && exit 1;
uaLog "-----------------------------------------------------------------------------------------"
uaLog "Docker Build Intiated with below arguments" "debug"
uaLog "DockerPath                    :              [${dockerpath}]" "info"
uaLog "DockerImageTag                :              [${imagetagname}]" "info"
uaLog "DockerBuildArgs               :              [${DockerBuildArgs}]" "info"
uaLog "-----------------------------------------------------------------------------------------"
uaLog "Authenticating into artifactory cloud docker registry" "debug"
uaLog "-----------------------------------------------------------------------------------------"
uaLog "Executing Docker Authentication Command" "info"
uaLog "COMMAND: docker login artifactorycloud.ual.com --username <+secrets.getValue('account.Harness_Jfrog_RW_User')> --password <+secrets.getValue('account.Harness_JfrogRW')>" "info"
uaLog "-----------------------------------------------------------------------------------------"
docker login artifactorycloud.ual.com --username <+secrets.getValue('account.Harness_Jfrog_RW_User')> --password <+secrets.getValue('account.Harness_JfrogRW')>
uaLog "Executing Docker Prune command to clean all the resources" "warn"
uaLog "-----------------------------------------------------------------------------------------"
uaLog "Executing Docker prune Command" "warn"
uaLog "COMMAND: docker system prune --all --force" "warn"
uaLog "-----------------------------------------------------------------------------------------"
docker system prune --all --force
uaLog "Initiating the Docker Build Commands to generate the image" "debug"
while ! docker ps ;do
    uaLog "Docker Command-Line Tool is not installed or available" "warn"
    sleep 1
done
uaLog "Docker DIND is detected" "success"
# if [[ ! -d "${dockerpath}" ]]; then
#    echo "Error: Dockerfile Folder Path ['${dockerpath}'] does not exist in the github repository"
#    exit 1
# fi
if [[ -z "${dockerpath}" ]]; then
    uaLog "Defaulting the docker file path location to root folder[.]" "critical"
    export dockerfilepath="-f ./Dockerfile ."
elif [[ -f "${dockerpath}/dockerfile" ]]; then
    uaLog "The docker file path location [${dockerpath}/dockerfile]" "critical"
    export dockerfilepath="-f ${dockerpath}/dockerfile ."
elif [[ -f "${dockerpath}/Dockerfile" ]]; then
    uaLog "The docker file path location [${dockerpath}/Dockerfile]" "critical"
    export dockerfilepath="-f ${dockerpath}/Dockerfile ."
else
    uaLog "No case-sensitive Dockerfile/dockerfile is found in DockerPath[${dockerpath}]"
fi
uaLog "Executing docker build commands to create docker image with tag[$imagetagname:<+codebase.tag>]" "debug"
uaLog "-----------------------------------------------------------------------------------------"
uaLog "Docker Build Command" "info"
uaLog "COMMAND: docker build $dockerfilepath -t myimage:<+codebase.tag> -t $imagetagname:<+codebase.tag> --build-arg=NUGET_PASSWORD=<+secrets.getValue('account.Harness_JfrogRW')> --build-arg=VERSION=<+codebase.tag> --build-arg=NUGET_URL=https://artifactorycloud.ual.com/artifactory/api/nuget/v3/v-nuget/index.json --build-arg=NUGET_USERNAME=<+secrets.getValue('account.Harness_Jfrog_RW_User')> ${DockerBuildArgs}" "info"
uaLog "-----------------------------------------------------------------------------------------"
docker build $dockerfilepath -t myimage:<+codebase.tag> -t $imagetagname:<+codebase.tag> --build-arg=NUGET_PASSWORD=<+secrets.getValue('account.Harness_JfrogRW')> --build-arg=VERSION=<+codebase.tag> --build-arg=NUGET_URL=https://artifactorycloud.ual.com/artifactory/api/nuget/v3/v-nuget/index.json --build-arg=NUGET_USERNAME=<+secrets.getValue('account.Harness_Jfrog_RW_User')> ${DockerBuildArgs}
uaLog "Listing the docker images" "success"
uaLog "-----------------------------------------------------------------------------------------"
uaLog "Listing Docker Images post build" "success"
uaLog "COMMAND: docker images" "success"
uaLog "-----------------------------------------------------------------------------------------"
docker images
 