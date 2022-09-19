#!/usr/bin/env bash

set -e

az config set extension.use_dynamic_install=yes_without_prompt > /dev/null

az extension add --name containerapp  --upgrade > /dev/null
az extension add --name rdbms-connect --upgrade > /dev/null
az extension add --name log-analytics --upgrade > /dev/null
