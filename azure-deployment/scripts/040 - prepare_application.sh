#!/usr/bin/env bash

set -e

function usage () { echo "How to use"; }

while getopts "D:h" option; do
  case "$option" in
    D) TARGET_FOLDER=$OPTARG;;
    h  ) usage ; exit;;
    \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
    *  ) echo "Unimplemented option: -$option" >&2; exit 1;
  esac
done

if [ ! "${TARGET_FOLDER}" ]; then
  usage
  exit 1
fi

#echo "#  Clone the GitHub repository of the application..."
#git -C "${TARGET_FOLDER}" pull || git clone https://github.com/quarkusio/quarkus-workshops.git "${TARGET_FOLDER}" --depth 1

echo "#  Checking Ports..."
# DIAGNOSTICS
#
# Errors are identified with messages on the standard error file.
# Lsof returns a one (1) if any error was detected, including the failure to locate command names,
#   file names, Internet addresses or files, login names, NFS files, PIDs, PGIDs, or UIDs it was asked to list.
#   If the -V option is specified, lsof will indicate the search items it failed to list.
#
# It returns a zero (0) if no errors were detected and if it was able to list some information about all the specified search arguments.
set +e
lsof -i tcp:8080    # UI
lsof -i tcp:8082    # Fight REST API
lsof -i tcp:8084    # Villain REST API
lsof -i tcp:8083    # Hero REST API
lsof -i tcp:5432    # Postgres
lsof -i tcp:9090    # Prometheus
lsof -i tcp:2181    # Zookeeper
lsof -i tcp:9092    # Kafka
set -e