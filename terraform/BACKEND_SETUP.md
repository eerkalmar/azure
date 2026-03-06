# Terraform Remote State Configuration

This file demonstrates how to configure remote state storage in Azure Storage.

## Option 1: Local State (Development/Testing)

By default, Terraform stores state locally in `terraform.tfstate`. This is suitable for development but NOT recommended for production.

## Option 2: Azure Storage Backend (Recommended for Production)

### Create Backend Resources

```bash
# Create resource group for Terraform state
az group create --name rg-terraform-state --location "East US"

# Create storage account (name must be globally unique and lowercase)
az storage account create \
  --resource-group rg-terraform-state \
  --name statergstorage123 \
  --sku Standard_LRS \
  --encryption-services blob

# Create blob container
az storage container create \
  --name tfstate \
  --account-name statergstorage123

# Get storage account access key
az storage account keys list \
  --resource-group rg-terraform-state \
  --account-name statergstorage123 \
  --query "[0].value" -o tsv
```

### Configure Terraform Backend

Create or uncomment the backend configuration in your Terraform files.

**File: `terraform/backend.tf`**

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "statergstorage123"
    container_name       = "tfstate"
    key                  = "keyvault.tfstate"
  }
}
```

### Initialize Terraform with Backend

```bash
# First initialize (creates .terraform directory locally)
cd terraform
terraform init

# When prompted about backend configuration, select "yes" to migrate state
```

### Security: Protect Storage Account

Lock down access to prevent unauthorized changes:

```bash
# Enable storage account encryption
az storage account update \
  --resource-group rg-terraform-state \
  --name statergstorage123 \
  --encryption-services blob \
  --encryption-require-infrastructure-encryption true

# Restrict storage account access with firewall (optional)
az storage account update \
  --resource-group rg-terraform-state \
  --name statergstorage123 \
  --default-action Deny

# Add service principal to allowed access
az storage account network-rule add \
  --resource-group rg-terraform-state \
  --account-name statergstorage123 \
  --ip-address <GITHUB_ACTIONS_IP> \
  --action Allow
```

### Store Backend Credentials as GitHub Secrets

Add these GitHub secrets for CI/CD pipeline:

```
TERRAFORM_BACKEND_RESOURCE_GROUP = rg-terraform-state
TERRAFORM_BACKEND_STORAGE_ACCOUNT = statergstorage123
TERRAFORM_BACKEND_CONTAINER = tfstate
TERRAFORM_BACKEND_KEY = keyvault.tfstate
TERRAFORM_BACKEND_ACCESS_KEY = <access-key-from-above>
```

## Option 3: Terraform Cloud/Enterprise

For enterprise deployments, consider using Terraform Cloud:

1. Create account at https://app.terraform.io
2. Generate API token
3. Configure remote backend:

```hcl
terraform {
  cloud {
    organization = "your-org"
    
    workspaces {
      name = "keyvault-prod"
    }
  }
}
```

## Remote State Benefits

- **Collaboration**: Multiple team members can work on same infrastructure
- **Locking**: Prevents concurrent modifications
- **Encryption**: State files are encrypted at rest
- **Backup**: Automatic backups and versioning
- **Audit**: Track who made what changes and when

## Managing State Files

### List all state files
```bash
az storage blob list --container-name tfstate --account-name statergstorage123
```

### Backup state file
```bash
az storage blob download \
  --container-name tfstate \
  --name keyvault.tfstate \
  --account-name statergstorage123 \
  --file keyvault.tfstate.backup
```

### State file recovery
If state becomes corrupted, restore from backup:

```bash
az storage blob upload \
  --container-name tfstate \
  --name keyvault.tfstate \
  --file keyvault.tfstate.backup \
  --account-name statergstorage123 \
  --overwrite
```

## Troubleshooting

**Error: "Unauthorized to access Backend"**
- Verify storage account key is correct
- Check firewall rules aren't blocking access
- Ensure service principal has Storage Blob Data Contributor role

**Error: "State file is locked"**
```bash
# View locks
terraform state list

# Force unlock (use cautiously)
terraform force-unlock <LOCK_ID>
```

**Need to clear backend and restart?**
```bash
# Remove local backend cache
rm -rf .terraform

# Reinitialize
terraform init
```
