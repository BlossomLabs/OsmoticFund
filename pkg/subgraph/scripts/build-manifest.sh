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

# -p manifest/templates/contracts/OsmoticController.template.yaml \
# -p manifest/templates/contracts/OsmoticPool.template.yaml \

mustache \
  -p manifest/templates/sources/MimeTokenFactories.yaml \
  -p manifest/templates/sources/ProjectRegistry.yaml \
  -p manifest/templates/contracts/MimeTokenFactory.template.yaml \
  -p manifest/templates/contracts/ProjectRegistry.template.yaml \
  $DATA \
  subgraph.template.yaml > subgraph.yaml
