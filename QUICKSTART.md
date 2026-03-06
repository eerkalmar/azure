# Quick Start Guide

This guide provides a fast path to deploying your Keyvault with GitHub Actions and Terraform.

## 5-Minute Setup

### Step 1: Create Service Principal (2 minutes)

```bash
# Login to Azure
az login

# Create service principal
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
az ad sp create-for-rbac --name "github-actions-sp" --role "Contributor" --scopes /subscriptions/$SUBSCRIPTION_ID
```

This will output:
```json
{
  "appId": "your-client-id",
  "displayName": "github-actions-sp",
  "password": "your-client-secret",
  "tenant": "your-tenant-id"
}
```

### Step 2: Get Object ID (1 minute)

```bash
az ad sp show --id {appId-from-above} --query "id" -o tsv
```

### Step 3: Add GitHub Secrets (1 minute)

In your GitHub repository, go to Settings → Secrets and variables → Actions, then add:

| Secret Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | appId from Step 1 |
| `AZURE_CLIENT_SECRET` | password from Step 1 |
| `AZURE_TENANT_ID` | tenant from Step 1 |
| `AZURE_SUBSCRIPTION_ID` | $SUBSCRIPTION_ID from Step 1 |
| `AZURE_BACKEND_OBJECT_ID` | Output from Step 2 |

### Step 4: Update Terraform Values (1 minute)

Edit `terraform/terraform.tfvars`:
```hcl
keyvault_name = "kv-mycompany-prod"  # Change to your desired name
location      = "East US"             # Change to your region if needed
```

### Step 5: Push and Deploy

```bash
# Create and checkout new branch
git checkout -b feature/keyvault-deployment

# Add files
git add .
git commit -m "Add Keyvault Terraform configuration"
git push origin feature/keyvault-deployment

# Create PR (GitHub will show the plan)
# Review plan in GitHub Actions
# Merge to main (this triggers the deployment)
```

## Verification

Once merged, check the Actions tab in GitHub for the workflow results. After successful completion:

```bash
# List your keyvaults
az keyvault list --resource-group rg-keyvault-prod
```

## You're Done! 🎉

Your Keyvault is now deployed and ready to use.

## Next: Add Secrets to Keyvault

Once the Keyvault is deployed, you can add secrets using Terraform:

```hcl
resource "azurerm_key_vault_secret" "db_password" {
  name         = "DBPassword"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.keyvault.id
}
```

Or via Azure CLI:

```bash
az keyvault secret set --vault-name kv-mycompany-prod \
  --name "MySecret" --value "MySecretValue"
```

## Troubleshooting

**Workflow fails with "Authentication failed"**
- Check that all 5 secrets are correctly set
- Verify the service principal has Contributor role

**"Keyvault name must be globally unique"**
- Change the name in `terraform.tfvars` to include a unique identifier
- Try: `kv-company-${random_string}`

**Need to destroy Keyvault?**
```bash
cd terraform
terraform destroy -auto-approve
```

## Full Guide

For comprehensive instructions and advanced configurations, see [KEYVAULT_DEPLOYMENT_GUIDE.md](../KEYVAULT_DEPLOYMENT_GUIDE.md)
