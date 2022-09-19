#!/usr/bin/env bash

set -e

function check_env_variables(){
  [ ! "${CONTAINERAPPS_ENVIRONMENT}" ] && echo "ERROR: Please set env variable CONTAINERAPPS_ENVIRONMENT" && exit 1

  [ ! "${POSTGRES_DB_ADMIN}" ] && echo "ERROR: Please set env variable POSTGRES_DB_ADMIN" && exit 1
  [ ! "${POSTGRES_DB_PWD}" ] && echo "ERROR: Please set env variable POSTGRES_DB_PWD" && exit 1

  [ ! "${KAFKA_BOOTSTRAP_SERVERS}" ] && echo "ERROR: Please set env variable KAFKA_BOOTSTRAP_SERVERS" && exit 1

  [ ! "${HEROES_APP}" ] && echo "ERROR: Please set env variable HEROES_APP" && exit 1
  [ ! "${HEROES_DB}" ] && echo "ERROR: Please set env variable HEROES_DB" && exit 1
  [ ! "${HEROES_IMAGE}" ] && echo "ERROR: Please set env variable HEROES_IMAGE" && exit 1
  [ ! "${HEROES_DB_CONNECT_STRING}" ] && echo "ERROR: Please set env variable HEROES_DB_CONNECT_STRING" && exit 1

  [ ! "${VILLAINS_APP}" ] && echo "ERROR: Please set env variable VILLAINS_APP" && exit 1
  [ ! "${VILLAINS_DB}" ] && echo "ERROR: Please set env variable VILLAINS_DB" && exit 1
  [ ! "${VILLAINS_IMAGE}" ] && echo "ERROR: Please set env variable VILLAINS_IMAGE" && exit 1
  [ ! "${VILLAINS_DB_CONNECT_STRING}" ] && echo "ERROR: Please set env variable VILLAINS_DB_CONNECT_STRING" && exit 1

  [ ! "${FIGHTS_APP}" ] && echo "ERROR: Please set env variable FIGHTS_APP" && exit 1
  [ ! "${FIGHTS_DB}" ] && echo "ERROR: Please set env variable FIGHTS_DB" && exit 1
  [ ! "${FIGHTS_IMAGE}" ] && echo "ERROR: Please set env variable FIGHTS_IMAGE" && exit 1
  [ ! "${FIGHTS_DB_CONNECT_STRING}" ] && echo "ERROR: Please set env variable FIGHTS_DB_CONNECT_STRING" && exit 1

  [ ! "${UI_APP}" ] && echo "ERROR: Please set env variable UI_APP" && exit 1
  [ ! "${UI_IMAGE}" ] && echo "ERROR: Please set env variable UI_IMAGE" && exit 1

    return 0
}

function usage() { echo "How to use"; }

while getopts "V:h" option; do
  case "$option" in
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

if [ ! "${VARIABLE_FILE_PATH}" ]; then
  usage
  exit 1
fi

echo "# Databases..."
echo "#   Parameters"
echo "#    VARIABLE_FILE_PATH=${VARIABLE_FILE_PATH}"

source "${VARIABLE_FILE_PATH}"

check_env_variables

echo "#  Deploying Container Apps..."
az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --tags system="$TAG" application="$HEROES_APP" \
  --image "$HEROES_IMAGE" \
  --name "$HEROES_APP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --ingress external \
  --target-port 8083 \
  --min-replicas 0 \
  --env-vars QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=validate \
             QUARKUS_HIBERNATE_ORM_SQL_LOAD_SCRIPT=no-file \
             QUARKUS_DATASOURCE_USERNAME="$POSTGRES_DB_ADMIN" \
             QUARKUS_DATASOURCE_PASSWORD="$POSTGRES_DB_PWD" \
             QUARKUS_DATASOURCE_REACTIVE_URL="$HEROES_DB_CONNECT_STRING"

HEROES_URL="https://$(az containerapp ingress show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$HEROES_APP" \
    --output json | jq -r .fqdn)"
echo "#     HEROES_URL:$HEROES_URL"

az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --tags system="$TAG" application="$VILLAINS_APP" \
  --image "$VILLAINS_IMAGE" \
  --name "$VILLAINS_APP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --ingress external \
  --target-port 8084 \
  --min-replicas 0 \
  --env-vars QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=validate \
             QUARKUS_HIBERNATE_ORM_SQL_LOAD_SCRIPT=no-file \
             QUARKUS_DATASOURCE_USERNAME="$POSTGRES_DB_ADMIN" \
             QUARKUS_DATASOURCE_PASSWORD="$POSTGRES_DB_PWD" \
             QUARKUS_DATASOURCE_JDBC_URL="$VILLAINS_DB_CONNECT_STRING"

VILLAINS_URL="https://$(az containerapp ingress show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VILLAINS_APP" \
    --output json | jq -r .fqdn)"
echo "#     VILLAINS_URL:$VILLAINS_URL"

az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --tags system="$TAG" application="$FIGHTS_APP" \
  --image "$FIGHTS_IMAGE" \
  --name "$FIGHTS_APP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --ingress external \
  --target-port 8082 \
  --min-replicas 0 \
  --env-vars QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=validate \
             QUARKUS_HIBERNATE_ORM_SQL_LOAD_SCRIPT=no-file \
             QUARKUS_DATASOURCE_USERNAME="$POSTGRES_DB_ADMIN" \
             QUARKUS_DATASOURCE_PASSWORD="$POSTGRES_DB_PWD" \
             QUARKUS_DATASOURCE_JDBC_URL="$FIGHTS_DB_CONNECT_STRING" \
             IO_QUARKUS_WORKSHOP_SUPERHEROES_FIGHT_CLIENT_HEROPROXY_MP_REST_URL="$HEROES_URL" \
             IO_QUARKUS_WORKSHOP_SUPERHEROES_FIGHT_CLIENT_VILLAINPROXY_MP_REST_URL="$VILLAINS_URL"

FIGHTS_URL="https://$(az containerapp ingress show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FIGHTS_APP" \
    --output json | jq -r .fqdn)"
echo "#     FIGHTS_URL:$FIGHTS_URL"

az containerapp create \
  --resource-group "$RESOURCE_GROUP" \
  --tags system="$TAG" application="$UI_APP" \
  --image "$UI_IMAGE" \
  --name "$UI_APP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --ingress external \
  --target-port 8080 \
  --env-vars API_BASE_URL="$FIGHTS_URL"
UI_URL="https://$(az containerapp ingress show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$UI_APP" \
    --output json | jq -r .fqdn)"
echo "#     UI_URL:$UI_URL"

echo "#  Application has been deployed."
echo "#    Please use the following commands to interact with it:"
echo "#      curl \"$HEROES_URL/api/heroes\" | jq"
echo "#      curl \"$VILLAINS_URL/api/villains\" | jq"
echo "#      curl \"$FIGHTS_URL/api/fights/randomfighters\" | jq"
echo "#      open \"$UI_URL\""
