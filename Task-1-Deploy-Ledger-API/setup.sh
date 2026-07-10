#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo " Ledger API Deployment"

echo
echo "Step 1/4 - Creating Cluster..."
./deploy/scripts/cluster.sh

echo
echo "Step 2/4 - Building Images..."
./deploy/scripts/build.sh

echo
echo "Step 3/4 - Deploying Application..."
./deploy/scripts/deploy.sh

echo
echo "Step 4/4 - Checking Status..."
./deploy/scripts/status.sh


echo " Setup Complete!"
