# Deploy Azure Keyvault with Terraform using GitHub Actions

This guide walks you through setting up GitHub Actions to automatically deploy an Azure Keyvault using Terraform.

## Prerequisites

- An Azure subscription
- A GitHub repository
- Azure CLI installed locally (for initial setup)
- Basic knowledge of Terraform and GitHub Actions

## Step 1: Create Azure Service Principal

GitHub Actions needs credentials to authenticate with Azure. Create a service principal for this purpose.

### Option A: Using Azure CLI

```bash
# Login to Azure
az login

# Create a service principal
az ad sp create-for-rbac --name "github-actions-sp" --role "Contributor" --scopes /subscriptions/{SUBSCRIPTION_ID}
```

Replace `{SUBSCRIPTION_ID}` with your Azure subscription ID.

### Option B: Using Azure Portal

1. Navigate to Azure Portal → Azure Active Directory → App registrations
2. Click "New registration"
3. Enter name: "github-actions-sp"
4. Click "Register"
5. In the app overview, copy the Application (client) ID and Tenant ID
6. Go to "Certificates & secrets" → "Client secrets" → "New client secret"
7. Create a secret and copy its value
8. Go to your subscription → IAM → Add role assignment
9. Select "Contributor" role
10. Assign the role to your service principal

### Store Credentials as GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Add these secrets:
   - `AZURE_CLIENT_ID`: Your service principal's client ID
   - `AZURE_CLIENT_SECRET`: Your service principal's client secret
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `AZURE_TENANT_ID`: Your Azure tenant ID

## Step 2: Create Terraform Configuration Files

Create the following directory structure in your repository:

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

### 2a. Create `terraform/main.tf`

This file defines the Keyvault resource:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Create Resource Group
resource "azurerm_resource_group" "keyvault_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Keyvault
resource "azurerm_key_vault" "keyvault" {
  name                       = var.keyvault_name
  location                   = azurerm_resource_group.keyvault_rg.location
  resource_group_name        = azurerm_resource_group.keyvault_rg.name
  tenant_id                  = var.tenant_id
  sku_name                   = var.sku_name
  enabled_for_disk_encryption = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.service_principal_object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "List",
      "Decrypt",
      "Sign",
      "Encrypt",
      "UnwrapKey",
      "WrapKey"
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover",
      "List"
    ]

    certificate_permissions = [
      "Create",
      "Delete",
      "Get",
      "List",
      "Update",
      "Import",
      "Purge",
      "Recover"
    ]
  }
}

# Optional: Add a secret
resource "azurerm_key_vault_secret" "example_secret" {
  name         = "ExampleSecret"
  value        = var.example_secret_value
  key_vault_id = azurerm_key_vault.keyvault.id
}
```

### 2b. Create `terraform/variables.tf`

This file defines input variables:

```hcl
variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "service_principal_object_id" {
  description = "Object ID of the service principal"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-keyvault-prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "keyvault_name" {
  description = "Name of the Key Vault (must be globally unique)"
  type        = string
  default     = "kv-terraform-demo"
}

variable "sku_name" {
  description = "SKU name for the Key Vault"
  type        = string
  default     = "standard"
}

variable "example_secret_value" {
  description = "Example secret value"
  type        = string
  default     = "example-secret-value"
  sensitive   = true
}
```

### 2c. Create `terraform/outputs.tf`

This file defines output values:

```hcl
output "keyvault_id" {
  description = "The ID of the created Key Vault"
  value       = azurerm_key_vault.keyvault.id
}

output "keyvault_name" {
  description = "The name of the created Key Vault"
  value       = azurerm_key_vault.keyvault.name
}

output "keyvault_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.keyvault.vault_uri
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.keyvault_rg.name
}
```

### 2d. Create `terraform/terraform.tfvars`

This file stores variable values (don't commit sensitive data here):

```hcl
resource_group_name = "rg-keyvault-prod"
location             = "East US"
keyvault_name        = "kv-company-prod-$(date +%s)"
sku_name             = "standard"
```

**Note:** For the Keyvault name, use a unique value. Azure requires globally unique names.

## Step 3: Get Service Principal Object ID

You need the service principal's object ID for the access policy. Get it using:

```bash
# Using Azure CLI
az ad sp list --filter "displayName eq 'github-actions-sp'" --query "[].id"

# Or using the client ID directly
az ad sp show --id {CLIENT_ID} --query "id"
```

Add this as a GitHub Secret:
- Secret name: `AZURE_BACKEND_OBJECT_ID`
- Value: The object ID from the command above

## Step 4: Create GitHub Actions Workflow

Create the GitHub Actions workflow file in your repository.

### Create `.github/workflows/deploy-keyvault.yml`

```yaml
name: Deploy Keyvault with Terraform

on:
  push:
    branches:
      - main
    paths:
      - 'terraform/**'
      - '.github/workflows/deploy-keyvault.yml'
  pull_request:
    branches:
      - main
    paths:
      - 'terraform/**'
  workflow_dispatch:

env:
  TERRAFORM_VERSION: 1.5.0
  TERRAFORM_WORKING_DIR: ./terraform

jobs:
  terraform:
    name: Terraform Plan & Apply
    runs-on: ubuntu-latest
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Terraform Format Check
        id: fmt
        run: terraform fmt -check -recursive
        working-directory: ${{ env.TERRAFORM_WORKING_DIR }}
        continue-on-error: true

      - name: Terraform Init
        id: init
        run: terraform init
        working-directory: ${{ env.TERRAFORM_WORKING_DIR }}

      - name: Terraform Validate
        id: validate
        run: terraform validate
        working-directory: ${{ env.TERRAFORM_WORKING_DIR }}

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color -out=tfplan
        working-directory: ${{ env.TERRAFORM_WORKING_DIR }}
        env:
          TF_VAR_client_id: ${{ secrets.AZURE_CLIENT_ID }}
          TF_VAR_client_secret: ${{ secrets.AZURE_CLIENT_SECRET }}
          TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          TF_VAR_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
          TF_VAR_service_principal_object_id: ${{ secrets.AZURE_BACKEND_OBJECT_ID }}

      - name: Terraform Apply
        id: apply
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve -no-color tfplan
        working-directory: ${{ env.TERRAFORM_WORKING_DIR }}

      - name: Get Terraform Outputs
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: terraform output -no-color
        working-directory: ${{ env.TERRAFORM_WORKING_DIR }}

      - name: Post Plan to PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const fs = require('fs');
            const planOutput = '${{ steps.plan.outputs.stdout }}';
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## Terraform Plan\n```\n' + planOutput + '\n```'
            });
```

## Step 5: Set Up Remote State (Optional but Recommended)

For production deployments, store Terraform state in Azure Storage instead of locally.

### Create Azure Storage Account for State

```bash
# Create resource group
az group create --name rg-terraform-state --location "East US"

# Create storage account
az storage account create --resource-group rg-terraform-state \
  --name statakeykeyvault --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name tfstate \
  --account-name statakeykeyvault

# Get storage account key
az storage account keys list --resource-group rg-terraform-state \
  --account-name statakeykeyvault --query "[0].value"
```

### Create `terraform/backend.tf`

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "statakeykeyvault"
    container_name       = "tfstate"
    key                  = "keyvault.tfstate"
  }
}
```

### Add GitHub Secrets for Backend

- `TERRAFORM_BACKEND_RESOURCE_GROUP`: rg-terraform-state
- `TERRAFORM_BACKEND_STORAGE_ACCOUNT`: statakeykeyvault
- `TERRAFORM_BACKEND_CONTAINER`: tfstate
- `TERRAFORM_BACKEND_KEY`: keyvault.tfstate
- `TERRAFORM_BACKEND_ACCESS_KEY`: (storage account key from above)

## Step 6: Test the Deployment

### Local Testing (Before Pushing)

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="client_id=$AZURE_CLIENT_ID" \
  -var="client_secret=$AZURE_CLIENT_SECRET" \
  -var="subscription_id=$AZURE_SUBSCRIPTION_ID" \
  -var="tenant_id=$AZURE_TENANT_ID" \
  -var="service_principal_object_id=$AZURE_BACKEND_OBJECT_ID"

# Apply if plan looks good
terraform apply
```

### GitHub Actions Testing

1. Push the workflow file and Terraform configs to your main branch
2. Go to GitHub repository → Actions
3. Select the "Deploy Keyvault with Terraform" workflow
4. Click "Run workflow" → "Run workflow"
5. Monitor the workflow execution
6. Once successful, verify the Keyvault in Azure Portal

## Step 7: Verify Deployment

### Using Azure Portal

1. Navigate to Azure Portal
2. Search for "Key vaults"
3. Verify your keyvault appears with the correct name and location
4. Open it to confirm access policies are set correctly

### Using Azure CLI

```bash
# List keyvaults
az keyvault list --resource-group rg-keyvault-prod

# Get keyvault details
az keyvault show --name kv-terraform-demo --resource-group rg-keyvault-prod

# List secrets
az keyvault secret list --vault-name kv-terraform-demo

# Retrieve a secret
az keyvault secret show --vault-name kv-terraform-demo --name ExampleSecret
```

## Troubleshooting

### Issue: Authentication Failed

**Solution:**
- Verify GitHub secrets are correctly set
- Confirm service principal has Contributor role on subscription
- Check that client secret hasn't expired

### Issue: Keyvault Name Not Unique

**Solution:**
- Keyvault names must be globally unique across all of Azure
- Include a timestamp or unique identifier in the name
- Use: `kv-company-${local.timestamp}` in Terraform

### Issue: Terraform Apply Doesn't Run on PR

**This is by design** - Apply only runs on pushes to main branch, not PRs for safety.

### Issue: State File Lock

**Solution:**
```bash
# If using remote state and it's locked:
terraform force-unlock <LOCK_ID>
```

## Security Best Practices

1. **Limit Service Principal Permissions**: Use minimal required permissions instead of Contributor
2. **Rotate Secrets Regularly**: Update service principal secrets every 90 days
3. **Protect Main Branch**: Require PR reviews before merging to main
4. **Use RBAC**: Consider using Azure AD roles for more granular control
5. **Enable Keyvault Purge Protection**: For production environments
6. **Monitor Access**: Enable Key Vault logging and monitoring
7. **Use Managed Identities**: For applications running in Azure

## Next Steps

- Add more secrets to the Keyvault using Terraform
- Implement approval gates for production deployments
- Set up notifications for deployment failures
- Add cost monitoring and budget alerts
- Implement disaster recovery and backup strategies

## Additional Resources

- [Azure Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions with Azure](https://github.com/Azure/login)
- [Terraform Best Practices](https://www.terraform.io/language)
