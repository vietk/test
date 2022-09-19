#!/bin/bash

set -e

function check_env_variables(){
  [ ! "${UNIQUE_IDENTIFIER}" ] && UNIQUE_IDENTIFIER=$(whoami) && export UNIQUE_IDENTIFIER

  [ ! "${CONTAINERAPPS_ENVIRONMENT}" ] && echo "ERROR: Please set env variable CONTAINERAPPS_ENVIRONMENT" && exit 1

  [ ! "${POSTGRES_DB_ADMIN}" ] && echo "ERROR: Please set env variable POSTGRES_DB_ADMIN" && exit 1
  [ ! "${POSTGRES_DB_PWD}" ] && echo "ERROR: Please set env variable POSTGRES_DB_PWD" && exit 1
  [ ! "${POSTGRES_DB_VERSION}" ] && echo "ERROR: Please set env variable POSTGRES_DB_VERSION" && exit 1
  [ ! "${POSTGRES_SKU}" ] && echo "ERROR: Please set env variable POSTGRES_SKU" && exit 1

  [ ! "${KAFKA_NAMESPACE}" ] && echo "ERROR: Please set env variable KAFKA_NAMESPACE" && exit 1
  [ ! "${KAFKA_TOPIC}" ] && echo "ERROR: Please set env variable KAFKA_TOPIC" && exit 1

  [ ! "${HEROES_APP}" ] && echo "ERROR: Please set env variable HEROES_APP" && exit 1
  [ ! "${HEROES_DB}" ] && echo "ERROR: Please set env variable HEROES_DB" && exit 1
  [ ! "${HEROES_DB_SCHEMA}" ] && echo "ERROR: Please set env variable HEROES_DB_SCHEMA" && exit 1

  [ ! "${VILLAINS_APP}" ] && echo "ERROR: Please set env variable VILLAINS_APP" && exit 1
  [ ! "${VILLAINS_DB}" ] && echo "ERROR: Please set env variable VILLAINS_DB" && exit 1
  [ ! "${VILLAINS_DB_SCHEMA}" ] && echo "ERROR: Please set env variable VILLAINS_DB_SCHEMA" && exit 1

  [ ! "${FIGHTS_APP}" ] && echo "ERROR: Please set env variable FIGHTS_APP" && exit 1
  [ ! "${FIGHTS_DB}" ] && echo "ERROR: Please set env variable FIGHTS_DB" && exit 1
  [ ! "${FIGHTS_DB_SCHEMA}" ] && echo "ERROR: Please set env variable FIGHTS_DB_SCHEMA" && exit 1

  return 0
}

function usage() { echo "How to use"; }

while getopts "r:l:T:L:R:I:V:h" option; do
  case "$option" in
  r) RESOURCE_GROUP=$OPTARG ;;
  l) LOCATION=$OPTARG ;;
  T) TAG=$OPTARG ;;
  L) LOG_ANALYTICS_WORKSPACE=$OPTARG ;;
  R) REGISTRY=$OPTARG ;;
  I) IMAGES_TAG=$OPTARG ;;
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

if [ ! "${RESOURCE_GROUP}" ] || [ ! "${LOCATION}" ] || [ ! "${TAG}" ] || [ ! "${LOG_ANALYTICS_WORKSPACE}" ] || [ ! "${REGISTRY}" ] || [ ! "${IMAGES_TAG}" ] || [ ! "${VARIABLE_FILE_PATH}" ]; then
  usage
  exit 1
fi

echo "# Deploying resources..."
echo "#   Parameters"
echo "#    RESOURCE_GROUP=${RESOURCE_GROUP}"
echo "#    LOCATION=${LOCATION}"
echo "#    TAG=${TAG}"
echo "#    LOG_ANALYTICS_WORKSPACE=${LOG_ANALYTICS_WORKSPACE}"
echo "#    REGISTRY=${REGISTRY}"
echo "#    IMAGES_TAG=${IMAGES_TAG}"
echo "#    VARIABLE_FILE_PATH=${VARIABLE_FILE_PATH}"

##################################################
echo "#   Creating Resource Group..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags system="${TAG}" > /dev/null

##################################################
echo "#   Creating Log Analytics Workspace..."
az monitor log-analytics workspace create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags system="${TAG}" \
  --workspace-name "${LOG_ANALYTICS_WORKSPACE}" > /dev/null

LOG_ANALYTICS_WORKSPACE_CLIENT_ID=$(az monitor log-analytics workspace show  \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${LOG_ANALYTICS_WORKSPACE}" \
  --query customerId  \
  --output tsv | tr -d '[:space:]')
echo "#     LOG_ANALYTICS_WORKSPACE_CLIENT_ID: ${LOG_ANALYTICS_WORKSPACE_CLIENT_ID}"

LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${LOG_ANALYTICS_WORKSPACE}" \
  --query primarySharedKey \
  --output tsv | tr -d '[:space:]')
echo "#     LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET: ${LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET}"

##################################################
echo "#   Creating Azure Container Registry..."
az acr create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags system="${TAG}" \
  --name "${REGISTRY}" \
  --workspace "${LOG_ANALYTICS_WORKSPACE}" \
  --sku Standard \
  --admin-enabled true > /dev/null

az acr update \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${REGISTRY}" \
  --anonymous-pull-enabled true > /dev/null

##################################################
echo "#   Loading Application variables..."
source "${VARIABLE_FILE_PATH}"
check_env_variables

##################################################
echo "#   Creating Container App..."
az containerapp env create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags system="${TAG}" \
  --name "${CONTAINERAPPS_ENVIRONMENT}" \
  --logs-workspace-id "${LOG_ANALYTICS_WORKSPACE_CLIENT_ID}" \
  --logs-workspace-key "${LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET}" > /dev/null

##################################################
echo "#   Creating the managed Postgres Databases..."
if [ -z "$(az postgres flexible-server show --resource-group "${RESOURCE_GROUP}" --name "${HEROES_DB}" --out tsv)" ]; then
  az postgres flexible-server create \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags system="${TAG}" application="${HEROES_APP}" \
  --name "${HEROES_DB}" \
  --admin-user "${POSTGRES_DB_ADMIN}" \
  --admin-password "${POSTGRES_DB_PWD}" \
  --public all \
  --sku-name "${POSTGRES_SKU}" \
  --storage-size 4096 \
  --version "${POSTGRES_DB_VERSION}" > /dev/null
fi

if [ -z "$(az postgres flexible-server show --resource-group "${RESOURCE_GROUP}" --name "${VILLAINS_DB}" --out tsv)" ]; then
  az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags system="$TAG" application="$VILLAINS_APP" \
    --name "$VILLAINS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --public all \
    --sku-name "$POSTGRES_SKU" \
    --storage-size 4096 \
    --version "$POSTGRES_DB_VERSION" > /dev/null
fi

if [ -z "$(az postgres flexible-server show --resource-group "${RESOURCE_GROUP}" --name "${FIGHTS_DB}" --out tsv)" ]; then
  az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags system="$TAG" application="$FIGHTS_APP" \
    --name "$FIGHTS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --public all \
    --sku-name "$POSTGRES_SKU" \
    --storage-size 4096 \
    --version "$POSTGRES_DB_VERSION" > /dev/null
fi
if [ -z "$(az postgres flexible-server db show --resource-group "${RESOURCE_GROUP}" --server-name "$HEROES_DB" --database-name "$HEROES_DB_SCHEMA" --out tsv)" ]; then
  az postgres flexible-server db create \
      --resource-group "$RESOURCE_GROUP" \
      --server-name "$HEROES_DB" \
      --database-name "$HEROES_DB_SCHEMA" > /dev/null
fi

if [ -z "$(az postgres flexible-server db show --resource-group "${RESOURCE_GROUP}" --server-name "$VILLAINS_DB" --database-name "$VILLAINS_DB_SCHEMA" --out tsv)" ]; then
  az postgres flexible-server db create \
    --resource-group "$RESOURCE_GROUP" \
    --server-name "$VILLAINS_DB" \
    --database-name "$VILLAINS_DB_SCHEMA" > /dev/null
fi

if [ -z "$(az postgres flexible-server db show --resource-group "${RESOURCE_GROUP}" --server-name "$FIGHTS_DB" --database-name "$FIGHTS_DB_SCHEMA" --out tsv)" ]; then
  az postgres flexible-server db create \
      --resource-group "$RESOURCE_GROUP" \
      --server-name "$FIGHTS_DB" \
      --database-name "$FIGHTS_DB_SCHEMA" > /dev/null
fi

##################################################
#echo "#   Creating the Managed Kafka..."
#az eventhubs namespace create \
#  --resource-group "$RESOURCE_GROUP" \
#  --location "$LOCATION" \
#  --tags system="$TAG" application="$FIGHTS_APP" \
#  --name "$KAFKA_NAMESPACE" > /dev/null
#
#az eventhubs eventhub create \
#  --resource-group "$RESOURCE_GROUP" \
#  --name "$KAFKA_TOPIC" \
#  --namespace-name "$KAFKA_NAMESPACE" > /dev/null
#
#KAFKA_CONNECTION_STRING=$(az eventhubs namespace authorization-rule keys list \
#  --resource-group "$RESOURCE_GROUP" \
#  --namespace-name "$KAFKA_NAMESPACE" \
#  --name RootManageSharedAccessKey \
#  --output json | jq -r .primaryConnectionString)
#
#JAAS_CONFIG='org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="'
#KAFKA_JAAS_CONFIG="${JAAS_CONFIG}${KAFKA_CONNECTION_STRING}\";"
#
#echo "#     KAFKA_CONNECTION_STRING:$KAFKA_CONNECTION_STRING"
#echo "#     KAFKA_JAAS_CONFIG:$KAFKA_JAAS_CONFIG"