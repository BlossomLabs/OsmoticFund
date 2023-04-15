#!/bin/bash

NETWORK=$1

if [ "$STAGING" ]
then
  FILE=$NETWORK'-staging.json'
else
  FILE=$NETWORK'.json'
fi

DATA=manifest/data/$FILE

echo 'Generating manifest from data file: '$DATA
cat $DATA


mustache \
  -p manifest/templates/sources/OsmoticController.yaml \
  -p manifest/templates/contracts/ProjectRegistry.template.yaml \
  -p manifest/templates/contracts/OsmoticController.template.yaml \
  -p manifest/templates/contracts/OwnableProjectList.template.yaml \
  -p manifest/templates/contracts/OsmoticPool.template.yaml \
  $DATA \
  subgraph.template.yaml > subgraph.yaml
