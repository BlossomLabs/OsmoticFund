#!/bin/bash

# Arguments
USER=$1
NAME=$2

if [ -z "${NETWORK}" ]; then
    NETWORK=local
fi

# Build manifest
echo ''
echo '> Building manifest file subgraph.yaml'
./scripts/build-manifest.sh $NETWORK

# Generate types
echo ''
echo '> Generating types'
graph codegen

# Prepare subgraph name
FULLNAME=$USER/$NAME-$NETWORK
if [ "$STAGING" ]; then
  FULLNAME=$FULLNAME-staging
fi
echo ''
echo '> Deploying subgraph: '$FULLNAME

# Deploy subgraph
graph deploy $FULLNAME \
  --node https://api.thegraph.com/deploy/ \
  --access-token $GRAPHKEY