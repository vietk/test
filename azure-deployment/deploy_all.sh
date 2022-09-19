#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -e

function check_env_variables(){
  [ ! "${SUBSCRIPTION_NAME}" ] && echo "ERROR: Please set env variable SUBSCRIPTION_NAME" && exit 1
  [ ! "${RESOURCE_GROUP}" ] && echo "ERROR: Please set env variable RESOURCE_GROUP" && exit 1
  [ ! "${LOCATION}" ] && echo "ERROR: Please set env variable LOCATION" && exit 1
  [ ! "${TAG}" ] && echo "ERROR: Please set env variable TAG" && exit 1
  [ ! "${LOG_ANALYTICS_WORKSPACE}" ] && echo "ERROR: Please set env variable LOG_ANALYTICS_WORKSPACE" && exit 1
  [ ! "${REGISTRY}" ] && echo "ERROR: Please set env variable REGISTRY" && exit 1
  [ ! "${IMAGES_TAG}" ] && echo "ERROR: Please set env variable IMAGES_TAG" && exit 1

  return 0
}

SCRIPTS_FOLDER="scripts"
APP_FOLDER="${SCRIPT_DIR}/.."

source variables.sh
check_env_variables

bash "${SCRIPTS_FOLDER}/000 - authenticate.sh" -S "${SUBSCRIPTION_NAME}"

bash "${SCRIPTS_FOLDER}/010 - configure_cli.sh"

bash "${SCRIPTS_FOLDER}/020 - configure_subscription.sh"

bash "${SCRIPTS_FOLDER}/030 - deploy_infra_resources.sh" -r "${RESOURCE_GROUP}" -l "${LOCATION}" -T "${TAG}" -L "${LOG_ANALYTICS_WORKSPACE}" -R "${REGISTRY}" -I "${IMAGES_TAG}" -V "${SCRIPTS_FOLDER}/999 - app_variables.sh"

bash "${SCRIPTS_FOLDER}/040 - prepare_application.sh" -D "${APP_FOLDER}"

bash "${SCRIPTS_FOLDER}/050 - build_containers.sh"  -D "${APP_FOLDER}" -V "${SCRIPTS_FOLDER}/999 - app_variables.sh"

# Population scripts to do not exits
#bash "${SCRIPTS_FOLDER}/060 - populate_db.sh"  -D "${APP_FOLDER}" -V "${SCRIPTS_FOLDER}/999 - app_variables.sh"

bash "${SCRIPTS_FOLDER}/070 - deploy_app.sh" -V "${SCRIPTS_FOLDER}/999 - app_variables.sh"

