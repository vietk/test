#!/bin/bash

set -e

function usage () { echo "How to use"; }

while getopts "S:h" option; do
  case "$option" in
    S) SUBSCRIPTION_NAME=$OPTARG;;
    h  ) usage ; exit;;
    \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
    *  ) echo "Unimplemented option: -$option" >&2; exit 1;
  esac
done

if [ ! "${SUBSCRIPTION_NAME}" ]; then
  usage
  exit 1
fi

echo "# Authenticating..."
echo "#   Parameters"
echo "#    SUBSCRIPTION_NAME=${SUBSCRIPTION_NAME}"

az account show 2> /dev/null || az login > /dev/null

az account set -s "${SUBSCRIPTION_NAME}" > /dev/null
