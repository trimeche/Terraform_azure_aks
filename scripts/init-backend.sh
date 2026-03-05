#!/bin/bash
# ============================================================
#  scripts/init-backend.sh
#  Creates the Azure Storage Account for Terraform remote state
#  Run ONCE before terraform init
#  Usage: ./scripts/init-backend.sh dev|prod
# ============================================================

set -euo pipefail

ENV=${1:-dev}
LOCATION="westeurope"
RG_NAME="rg-terraform-state"
SA_NAME="sttfstate${ENV}001"
CONTAINER="tfstate"

echo ">>> Creating Terraform backend for ENV=$ENV"

az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"

az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA_NAME"

echo ">>> Done. Now run:"
echo "    terraform init -backend-config=environments/${ENV}/backend.conf"
