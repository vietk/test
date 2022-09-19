function check_env_variables(){
  [ ! "${UNIQUE_IDENTIFIER}" ] && UNIQUE_IDENTIFIER=$(whoami) && export UNIQUE_IDENTIFIER

  [ ! "${REGISTRY_URL}" ] && echo "ERROR: Please set env variable REGISTRY_URL" && exit 1
  [ ! "${IMAGES_TAG}" ] && echo "ERROR: Please set env variable IMAGES_TAG" && exit 1

    return 0
}

if [ ! "${REGISTRY_URL}" ]; then
  [ ! "${RESOURCE_GROUP}" ] && echo "ERROR: Please set env variable RESOURCE_GROUP" && exit 1
  [ ! "${REGISTRY}" ] && echo "ERROR: Please set env variable REGISTRY" && exit 1

  REGISTRY_URL=$(az acr show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${REGISTRY}" \
    --query "loginServer" \
    --output tsv)
  export REGISTRY_URL
fi

check_env_variables

# Container Apps
export CONTAINERAPPS_ENVIRONMENT="super-heroes-env"

# Postgres
export POSTGRES_DB_ADMIN="superheroesadmin"
export POSTGRES_DB_PWD="super-heroes-p#ssw0rd-12046"
export POSTGRES_DB_VERSION="13"
export POSTGRES_SKU="Standard_D2s_v3"
export POSTGRES_TIER="GeneralPurpose"

# Kafka
export KAFKA_NAMESPACE="fights-kafka-$UNIQUE_IDENTIFIER"
export KAFKA_TOPIC="fights"
export KAFKA_BOOTSTRAP_SERVERS="$KAFKA_NAMESPACE.servicebus.windows.net:9093"

# Heroes
export HEROES_APP="heroes-app"
export HEROES_DB="heroes-db-$UNIQUE_IDENTIFIER"
export HEROES_IMAGE="${REGISTRY_URL}/${HEROES_APP}:${IMAGES_TAG}"
export HEROES_DB_SCHEMA="heroes"
export HEROES_DB_CONNECT_STRING="postgresql://${HEROES_DB}.postgres.database.azure.com:5432/${HEROES_DB_SCHEMA}?ssl=true&sslmode=require"

# Villains
export VILLAINS_APP="villains-app"
export VILLAINS_DB="villains-db-$UNIQUE_IDENTIFIER"
export VILLAINS_IMAGE="${REGISTRY_URL}/${VILLAINS_APP}:${IMAGES_TAG}"
export VILLAINS_DB_SCHEMA="villains"
export VILLAINS_DB_CONNECT_STRING="jdbc:postgresql://${VILLAINS_DB}.postgres.database.azure.com:5432/${VILLAINS_DB_SCHEMA}?ssl=true&sslmode=require"

# Fights
export FIGHTS_APP="fights-app"
export FIGHTS_DB="fights-db-$UNIQUE_IDENTIFIER"
export FIGHTS_IMAGE="${REGISTRY_URL}/${FIGHTS_APP}:${IMAGES_TAG}"
export FIGHTS_DB_SCHEMA="fights"
export FIGHTS_DB_CONNECT_STRING="jdbc:postgresql://${FIGHTS_DB}.postgres.database.azure.com:5432/${FIGHTS_DB_SCHEMA}?ssl=true&sslmode=require"

# UI
export UI_APP="super-heroes-ui"
export UI_IMAGE="${REGISTRY_URL}/${UI_APP}:${IMAGES_TAG}"