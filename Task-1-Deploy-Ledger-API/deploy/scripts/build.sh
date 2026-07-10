#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Building Images"


docker build \
    -t ledger-api:starter \
    -f app/Dockerfile \
    app


kind load docker-image ledger-api:starter --name ledger-api


echo
echo "Images built and loaded into Kind."