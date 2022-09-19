#!/usr/bin/env bash

set -e

function check_env_variables(){

  [ ! "${POSTGRES_DB_ADMIN}" ] && echo "ERROR: Please set env variable POSTGRES_DB_ADMIN" && exit 1
  [ ! "${POSTGRES_DB_PWD}" ] && echo "ERROR: Please set env variable POSTGRES_DB_PWD" && exit 1

  [ ! "${HEROES_DB}" ] && echo "ERROR: Please set env variable HEROES_DB" && exit 1
  [ ! "${HEROES_DB_SCHEMA}" ] && echo "ERROR: Please set env variable HEROES_DB_SCHEMA" && exit 1

  [ ! "${VILLAINS_DB}" ] && echo "ERROR: Please set env variable VILLAINS_DB" && exit 1
  [ ! "${VILLAINS_DB_SCHEMA}" ] && echo "ERROR: Please set env variable VILLAINS_DB_SCHEMA" && exit 1

  [ ! "${FIGHTS_DB}" ] && echo "ERROR: Please set env variable FIGHTS_DB" && exit 1
  [ ! "${FIGHTS_DB_SCHEMA}" ] && echo "ERROR: Please set env variable FIGHTS_DB_SCHEMA" && exit 1

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

echo "# Databases..."
echo "#   Parameters"
echo "#    PROJECT_FOLDER=${PROJECT_FOLDER}"
echo "#    VARIABLE_FILE_PATH=${VARIABLE_FILE_PATH}"

source "${VARIABLE_FILE_PATH}"

check_env_variables

pushd "${PROJECT_FOLDER}/quarkus-workshop-super-heroes/super-heroes"

echo "#  Creating the database schemas..."
az postgres flexible-server execute \
    --name "$HEROES_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$HEROES_DB_SCHEMA" \
    --file-path "infrastructure/db-init/initialize-tables-heroes.sql"

az postgres flexible-server execute \
    --name "$VILLAINS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$VILLAINS_DB_SCHEMA" \
    --file-path "infrastructure/db-init/initialize-tables-villains.sql"

az postgres flexible-server execute \
    --name "$FIGHTS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$FIGHTS_DB_SCHEMA" \
    --file-path "infrastructure/db-init/initialize-tables-fights.sql"

echo "#  Populating the database..."
az postgres flexible-server execute \
    --name "$HEROES_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$HEROES_DB_SCHEMA" \
    --file-path "rest-heroes/src/main/resources/import.sql"

az postgres flexible-server execute \
    --name "$VILLAINS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$VILLAINS_DB_SCHEMA" \
    --file-path "rest-villains/src/main/resources/import.sql"

az postgres flexible-server execute \
    --name "$FIGHTS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$FIGHTS_DB_SCHEMA" \
    --file-path "rest-fights/src/main/resources/import.sql"

echo "#  Checking if content has been correctly populated..."
az postgres flexible-server execute \
    --name "$HEROES_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$HEROES_DB_SCHEMA" \
    --querytext "select * from hero"

az postgres flexible-server execute \
    --name "$VILLAINS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$VILLAINS_DB_SCHEMA" \
    --querytext "select * from villain"

az postgres flexible-server execute \
    --name "$FIGHTS_DB" \
    --admin-user "$POSTGRES_DB_ADMIN" \
    --admin-password "$POSTGRES_DB_PWD" \
    --database-name "$FIGHTS_DB_SCHEMA" \
    --querytext "select * from fight"

popd