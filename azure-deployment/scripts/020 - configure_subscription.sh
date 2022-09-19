#!/usr/bin/env bash

set -e

az provider register --namespace Microsoft.App                  > /dev/null
az provider register --namespace Microsoft.OperationalInsights  > /dev/null
az provider register --namespace Microsoft.ContainerRegistry    > /dev/null
az provider register --namespace Microsoft.Insights             > /dev/null
az provider register --namespace Microsoft.DBforPostgreSQL      > /dev/null
