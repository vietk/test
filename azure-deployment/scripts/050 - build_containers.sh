#!/usr/bin/env bash

set -e

function check_env_variables(){
  [ ! "${HEROES_IMAGE}" ] && echo "ERROR: Please set env variable HEROES_IMAGE" && exit 1

  [ ! "${VILLAINS_IMAGE}" ] && echo "ERROR: Please set env variable VILLAINS_IMAGE" && exit 1

  [ ! "${FIGHTS_IMAGE}" ] && echo "ERROR: Please set env variable FIGHTS_IMAGE" && exit 1

  [ ! "${UI_IMAGE}" ] && echo "ERROR: Please set env variable UI_IMAGE" && exit 1

    return 0
}

function usage() { echo "How to use"; }

while getopts "D:V:h" option; do
  case "$option" in
  D) PROJECT_FOLDER=$OPTARG ;;
  V) VARIABLE_FILE_PATH=$OPTARG ;;
  h)
    usage
    exit
    ;;
  \?)
    echo "Unknown option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Missing option argument for -$OPTARG" >&2
    exit 1
    ;;
  *)
    echo "Unimplemented option: -$option" >&2
    exit 1
    ;;
  esac
done

if [ ! "${PROJECT_FOLDER}" ] || [ ! "${VARIABLE_FILE_PATH}" ]; then
  usage
  exit 1
fi

echo "# Container Images..."
echo "#   Parameters"
echo "#    PROJECT_FOLDER=${PROJECT_FOLDER}"
echo "#    VARIABLE_FILE_PATH=${VARIABLE_FILE_PATH}"

source "${VARIABLE_FILE_PATH}"

pushd "${PROJECT_FOLDER}"
check_env_variables

echo "#  Building application containers..."

pushd heroes-app
docker build -f src/main/docker/Dockerfile.build-native -t quarkus/rest-heroes .
popd

pushd villains-app
docker build -f src/main/docker/Dockerfile.build-native -t quarkus/rest-villains ../..
popd

pushd fights-app
docker build -f src/main/docker/Dockerfile.build-native -t quarkus/rest-fights .
popd

#pushd super-heroes-ui
#docker build -f src/main/docker/Dockerfile.build-native -t quarkus/ui-super-heroes .
#popd

docker image ls | grep quarkus

echo "#   Pushing container to Azure Container Registry"
#docker tag quarkus/ui-super-heroes:latest   "$UI_IMAGE"
docker tag quarkus/rest-fights:latest       "$FIGHTS_IMAGE"
docker tag quarkus/rest-villains:latest     "$VILLAINS_IMAGE"
docker tag quarkus/rest-heroes:latest       "$HEROES_IMAGE"

az acr login \
  --name "$REGISTRY"

#docker push "$UI_IMAGE"
docker push "$FIGHTS_IMAGE"
docker push "$VILLAINS_IMAGE"
docker push "$HEROES_IMAGE"

az acr repository list \
  --name "$REGISTRY" \
  --output table

popd
