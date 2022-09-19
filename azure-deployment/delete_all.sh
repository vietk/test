#!/usr/bin/env bash

set -e

SCRIPTS_FOLDER="scripts"

source variables.sh

bash "${SCRIPTS_FOLDER}/010 - authenticate.sh" -S "${SUBSCRIPTION_NAME}"

az group delete \
  --name "$RESOURCE_GROUP"