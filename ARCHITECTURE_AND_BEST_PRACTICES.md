# Architecture and Best Practices

This document explains the architecture of the Azure Keyvault deployment solution and provides best practices.

## Solution Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Repository                      │
│  ┌─────────────────────────────────────────────────────┐ │
│  │         GitHub Actions Workflow                     │ │
│  │  (deploy-keyvault.yml)                             │ │
│  │  - Terraform Plan                                  │ │
│  │  - Terraform Apply                                 │ │
│  └──────────────────┬──────────────────────────────────┘ │
└─────────────────────┼──────────────────────────────────────┘
                      │
                      │ (Authenticate via)
                      ▼
         ┌────────────────────────────┐
         │  Service Principal         │
         │  (github-actions-sp)       │
         │  - Client ID               │
         │  - Client Secret           │
         │  - Tenant ID               │
         └────────────────┬───────────┘
                          │
         ┌────────────────┴──────────────────────┐
         ▼                                        ▼
    ┌─────────────────┐              ┌──────────────────────┐
    │  Azure AD       │              │  Azure Resources     │
    │  (Tenant)       │              │  - Key Vault         │
    │                 │              │  - Resource Group    │
    │                 │              │  - Storage (State)   │
    └─────────────────┘              └──────────────────────┘
```

## Component Overview

### 1. GitHub Actions Workflow
- **File**: `.github/workflows/deploy-keyvault.yml`
- **Purpose**: Orchestrates the deployment process
- **Triggers**: 
  - Push to main branch
  - Pull requests against main
  - Manual workflow dispatch

**Key Steps**:
1. Checkout code
2. Setup Terraform
3. Format validation
4. Terraform init
5. Terraform validate
6. Terraform plan
7. Terraform apply (on main push only)

### 2. Service Principal
- **Name**: `github-actions-sp`
- **Purpose**: Enables GitHub Actions to authenticate with Azure
- **Role**: Contributor (on subscription level)
- **Credentials**: Stored as GitHub Secrets

**Security**:
- Stored securely in GitHub Secrets vault
- Limited to specific subscription
- Should be rotated regularly

### 3. Terraform Configuration
- **Location**: `terraform/` directory
- **Files**:
  - `main.tf`: Core resource definitions
  - `variables.tf`: Input variables
  - `outputs.tf`: Output values
  - `terraform.tfvars`: Variable values
  - `backend.tf` (optional): Remote state configuration

### 4. Azure Resources
- **Key Vault**: Centralized secrets management
- **Resource Group**: Logical container for resources
- **Storage Account** (optional): For remote state

## Deployment Flow

### Pull Request Flow
```
1. Developer pushes changes → Feature branch
2. Creates Pull Request
3. GitHub Actions runs:
   - Terraform format check
   - Terraform validate
   - Terraform plan
4. Plan output posted to PR
5. Code reviewers verify changes
6. Merge to main (if approved)
```

### Production Deployment Flow
```
1. Changes merged to main branch
2. GitHub Actions workflow triggered
3. Terraform validates changes
4. Terraform applies changes
5. Azure creates/updates resources
6. Workflow provides outputs
```

## Security Best Practices

### 1. Authentication & Authorization
```hcl
# ✅ Good: Limited permissions
resource "azurerm_role_assignment" "github_actions" {
  scope              = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id       = azurerm_client_config.current.object_id
}

# ❌ Bad: Owner role (too permissive)
role_definition_name = "Owner"
```

### 2. Secrets Management
```bash
# ✅ Good: Using GitHub Secrets vault
gh secret set AZURE_CLIENT_SECRET --body "secret-value"

# ❌ Bad: Committing secrets to repository
echo "password123" >> config.tf
```

### 3. State File Protection
```hcl
# Remote state with encryption
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "terraformstate"
    container_name       = "tfstate"
    key                  = "keyvault.tfstate"
  }
}
```

### 4. Branch Protection
- Require PR reviews before merging to main
- Require status checks to pass
- Dismiss stale PR approvals

### 5. Key Vault Security
```hcl
# ✅ Good: Production hardened settings
resource "azurerm_key_vault" "keyvault" {
  purge_protection_enabled   = true
  soft_delete_retention_days = 90
  enabled_for_disk_encryption = true
  
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```

## Variables and Naming Conventions

### Environment-Specific Variables
```hcl
# Use separate terraform.tfvars for each environment
# terraform/environments/prod.tfvars
environment = "prod"
keyvault_name = "kv-comp-prod"

# terraform/environments/dev.tfvars
environment = "dev"
keyvault_name = "kv-comp-dev"
```

### Naming Convention
Use consistent naming:
- **Resource groups**: `rg-<project>-<env>`
- **Key Vaults**: `kv-<company>-<env>`
- **Storage**: `st<project><env>` (lowercase, no hyphens)
- **Secrets**: `PascalCase` or `kebab-case`

```hcl
# Example
resource_group_name = "rg-keyvault-prod"
keyvault_name      = "kv-company-prod"
location           = "East US"
```

## Terraform State Management

### Local State (Development Only)
```bash
# Suitable for individual development
terraform init

# State stored in: terraform.tfstate
# ⚠️  Do NOT use for production
```

### Remote State (Production)
```bash
# State stored in Azure Storage
terraform init

# Benefits:
# - Collaboration
# - Encryption at rest
# - Automatic backups
# - State locking
# - Audit trail
```

### State File Lifecycle
```bash
# Backup state
terraform state pull > backup.tfstate

# List resources in state
terraform state list

# Show resource details
terraform state show azurerm_key_vault.keyvault

# Remove resource from state (keeps resource in Azure)
terraform state rm azurerm_key_vault.keyvault
```

## Scaling Patterns

### Multi-Environment Setup
```
environments/
├── dev/
│  ├── main.tf
│  ├── terraform.tfvars
│  └── backend.tf
├── staging/
│  ├── main.tf
│  ├── terraform.tfvars
│  └── backend.tf
└── prod/
   ├── main.tf
   ├── terraform.tfvars
   └── backend.tf
```

### Multi-Workspace Approach
```bash
# Create workspaces for environments
terraform workspace new dev
terraform workspace new prod

# Switch between workspaces
terraform workspace select dev

# Use in workflow
terraform apply -var-file="${TF_WORKSPACE}.tfvars"
```

### Modules for Reusability
```hcl
# modules/keyvault/main.tf
module "keyvault" {
  source = "./modules/keyvault"
  
  name              = var.keyvault_name
  resource_group    = var.resource_group_name
  location          = var.location
  tenant_id         = var.tenant_id
  object_id         = var.service_principal_object_id
}
```

## Monitoring and Observability

### Enable Key Vault Logging
```hcl
resource "azurerm_key_vault" "keyvault" {
  # ... other config ...
  
  depends_on = [azurerm_key_vault_access_policy.logging]
}

resource "azurerm_monitor_diagnostic_setting" "keyvault_logs" {
  name               = "keyvault-logs"
  target_resource_id = azurerm_key_vault.keyvault.id
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  log {
    category = "AuditEvent"
    enabled  = true
  }
}
```

### GitHub Actions Notifications
```yaml
- name: Slack Notification
  if: always()
  uses: slackapi/slack-github-action@v1.24.0
  with:
    payload: |
      {
        "text": "Keyvault deployment ${{ job.status }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Deployment ${{ job.status }}*\n${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            }
          }
        ]
      }
```

## Disaster Recovery

### State File Recovery
```bash
# If state file is corrupted:
# 1. Create manual backup
terraform state pull > backup.tfstate

# 2. Restore from previous version
az storage blob download \
  --container-name tfstate \
  --name keyvault.tfstate.previous \
  --account-name terraformstate \
  --file keyvault.tfstate

# 3. Re-import state
terraform refresh
```

### Resource Recovery
```bash
# If Key Vault is accidentally deleted (within soft delete period)
az keyvault recover --name kv-company-prod --resource-group rg-keyvault-prod

# Purge the Key Vault (permanent deletion)
az keyvault purge --name kv-company-prod
```

## Cost Optimization

### Key Vault Pricing Tiers
```hcl
# Standard (cheaper, good for dev/test)
sku_name = "standard"

# Premium (hardware security modules, for production)
sku_name = "premium"
```

### Cost Monitoring
```bash
# List Key Vault objects (factors into billing)
az keyvault key list --vault-name kv-company-prod
az keyvault secret list --vault-name kv-company-prod
```

## Troubleshooting Matrix

| Issue | Cause | Solution |
|-------|-------|----------|
| Authentication failed | Invalid credentials | Verify GitHub secrets |
| State lock | Concurrent runs | Wait or force-unlock |
| Name conflict | Name exists globally | Change to unique name |
| Access denied | Insufficient permissions | Add access policy |
| Plan drift | Manual changes in portal | Run terraform apply |

## Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/guides)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Terraform State Management](https://www.terraform.io/language/state)
