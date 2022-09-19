#!/usr/bin/env bash
UNIQUE_IDENTIFIER=$(whoami)
export UNIQUE_IDENTIFIER

export SUBSCRIPTION_NAME="xxxxx"

export RESOURCE_GROUP="super-heroes"
export LOCATION="westeurope"
export TAG="super-heroes"
export LOG_ANALYTICS_WORKSPACE="super-heroes-logs"
export REGISTRY="superheroesregistry"${UNIQUE_IDENTIFIER}
export IMAGES_TAG="1.0"