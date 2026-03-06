# Advanced Usage Guide

This guide covers advanced scenarios and integrations with your deployed Azure Key Vault.

## Table of Contents
1. [Managing Secrets](#managing-secrets)
2. [Using Key Vault in Applications](#using-key-vault-in-applications)
3. [Advanced Terraform Scenarios](#advanced-terraform-scenarios)
4. [CI/CD Integration](#cicd-integration)
5. [Disaster Recovery](#disaster-recovery)

## Managing Secrets

### Add Secrets via Terraform

```hcl
# terraform/main.tf

# Database credentials
resource "azurerm_key_vault_secret" "db_password" {
  name         = "DBPassword"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.keyvault.id
  
  depends_on = [azurerm_key_vault.keyvault]
}

# API keys
resource "azurerm_key_vault_secret" "api_key" {
  name         = "APIKey"
  value        = var.api_key
  key_vault_id = azurerm_key_vault.keyvault.id
}

# Connection strings
resource "azurerm_key_vault_secret" "connection_string" {
  name         = "ConnectionString"
  value        = "Server=myserver;Database=mydb;User=myuser;Password=${var.db_password}"
  key_vault_id = azurerm_key_vault.keyvault.id
}
```

### Add Secrets via Azure CLI

```bash
# Set a simple secret
az keyvault secret set \
  --vault-name kv-company-prod \
  --name "MySecret" \
  --value "MySecretValue"

# Set a multi-line secret
az keyvault secret set \
  --vault-name kv-company-prod \
  --name "SSHPrivateKey" \
  --file ~/.ssh/id_rsa

# Set a secret from environment variable
export MY_PASSWORD="SecurePassword123!"
az keyvault secret set \
  --vault-name kv-company-prod \
  --name "DatabasePassword" \
  --value "$MY_PASSWORD"

# Retrieve a secret
az keyvault secret show \
  --vault-name kv-company-prod \
  --name "MySecret" \
  --query "value" -o tsv

# List all secrets
az keyvault secret list --vault-name kv-company-prod

# Update a secret (creates new version)
az keyvault secret set \
  --vault-name kv-company-prod \
  --name "MySecret" \
  --value "UpdatedValue"

# View secret versions
az keyvault secret list-versions \
  --vault-name kv-company-prod \
  --name "MySecret"

# Restore previous secret version
SECRET_VERSION="abc123..."
az keyvault secret show \
  --vault-name kv-company-prod \
  --name "MySecret" \
  --version "$SECRET_VERSION"
```

### Manage Keys (not just secrets)

```hcl
# Create a key for encryption
resource "azurerm_key_vault_key" "encryption_key" {
  name            = "EncryptionKey"
  key_vault_id    = azurerm_key_vault.keyvault.id
  key_type        = "RSA"
  key_size        = 2048
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}

output "encryption_key_id" {
  value = azurerm_key_vault_key.encryption_key.id
}
```

### Manage Certificates

```hcl
# Create a self-signed certificate
resource "azurerm_key_vault_certificate" "self_signed" {
  name             = "MySSLCertificate"
  key_vault_id     = azurerm_key_vault.keyvault.id
  
  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      
      trigger {
        days_before_expiry = 30
      }
    }
    
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    
    x509_certificate_properties {
      subject            = "CN=example.com"
      validity_in_months = 12
    }
  }
}

# Import an existing certificate
resource "azurerm_key_vault_certificate" "imported" {
  name             = "MyImportedCert"
  key_vault_id     = azurerm_key_vault.keyvault.id
  certificate_data = base64encode(file("./certificate.pfx"))
  certificate_password = var.cert_password
}
```

## Using Key Vault in Applications

### .NET / C# Application

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

// Create a client
var client = new SecretClient(
    new Uri("https://kv-company-prod.vault.azure.net/"),
    new DefaultAzureCredential()
);

// Get a secret
KeyVaultSecret secret = await client.GetSecretAsync("MySecret");
string secretValue = secret.Value;

// Set a secret
await client.SetSecretAsync("NewSecret", "SecretValue");

// Get secret with specific version
KeyVaultSecret versionedSecret = await client.GetSecretAsync("MySecret", "abc123...");
```

### Python Application

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Create a client
credential = DefaultAzureCredential()
client = SecretClient(
    vault_url="https://kv-company-prod.vault.azure.net/",
    credential=credential
)

# Get a secret
secret = client.get_secret("MySecret")
print(secret.value)

# Set a secret
client.set_secret("NewSecret", "SecretValue")

# List all secrets
secrets = client.list_properties_of_secrets()
for secret_properties in secrets:
    print(secret_properties.name)

# Delete a secret
client.begin_delete_secret("OldSecret")
```

### Node.js / JavaScript Application

```javascript
const { SecretClient } = require("@azure/keyvault-secrets");
const { DefaultAzureCredential } = require("@azure/identity");

// Create a client
const credential = new DefaultAzureCredential();
const client = new SecretClient(
    "https://kv-company-prod.vault.azure.net/",
    credential
);

// Get a secret
const secret = await client.getSecret("MySecret");
console.log(secret.value);

// Set a secret
await client.setSecret("NewSecret", "SecretValue");

// List all secrets
for await (let secretProperties of client.listPropertiesOfSecrets()) {
    console.log(secretProperties.name);
}
```

### Environment Variable Injection

```bash
# Export secret as environment variable
export DB_PASSWORD=$(
  az keyvault secret show \
    --vault-name kv-company-prod \
    --name "DBPassword" \
    --query "value" -o tsv
)

# Use in application startup
node my-app.js
```

## Advanced Terraform Scenarios

### Multi-Environment Setup

```hcl
# terraform/environments/prod.tfvars
resource_group_name = "rg-keyvault-prod"
keyvault_name        = "kv-company-prod"
location             = "East US"
sku_name             = "premium"
purge_protection     = true
soft_delete_days     = 90

# terraform/environments/dev.tfvars
resource_group_name = "rg-keyvault-dev"
keyvault_name        = "kv-company-dev"
location             = "East US"
sku_name             = "standard"
purge_protection     = false
soft_delete_days     = 7
```

Deploy to specific environment:
```bash
terraform apply -var-file="environments/prod.tfvars"
```

### Using Terraform Workspaces

```bash
# Create workspaces
terraform workspace new prod
terraform workspace new dev

# Apply to specific workspace
terraform workspace select prod
terraform apply -var-file="prod.tfvars"

terraform workspace select dev
terraform apply -var-file="dev.tfvars"

# List workspaces
terraform workspace list
```

### Conditional Resource Creation

```hcl
variable "enable_purge_protection" {
  type    = bool
  default = false
}

resource "azurerm_key_vault" "keyvault" {
  # ... other config ...
  purge_protection_enabled = var.enable_purge_protection
  
  dynamic "access_policy" {
    for_each = var.enable_advanced_access ? [1] : []
    content {
      # Additional access policies for advanced scenarios
    }
  }
}
```

### Data Source Usage

```hcl
# Reference existing Key Vault
data "azurerm_key_vault" "existing" {
  name                = "kv-existing"
  resource_group_name = "rg-existing"
}

# Use in other resources
resource "azurerm_key_vault_access_policy" "additional_policy" {
  key_vault_id = data.azurerm_key_vault.existing.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.myapp.principal_id
  
  secret_permissions = ["Get", "List"]
}
```

### Output Secrets to Other Resources

```hcl
# Store Keyvault connection info for applications
resource "azurerm_app_service_slot_config" "app" {
  app_service_id          = azurerm_app_service.myapp.id
  slot_name               = "staging"
  
  app_settings = {
    "KeyVaultUrl"  = azurerm_key_vault.keyvault.vault_uri
    "KeyVaultName" = azurerm_key_vault.keyvault.name
  }
}

# Or output for team use
output "keyvault_connection_string" {
  value       = "https://${azurerm_key_vault.keyvault.name}.vault.azure.net/"
  description = "URL to connect to Key Vault"
}
```

## CI/CD Integration

### GitHub Actions: Automated Secret Rotation

```yaml
name: Rotate Database Password

on:
  schedule:
    # Run every 90 days
    - cron: '0 0 1 */3 *'
  workflow_dispatch:

jobs:
  rotate-secrets:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
      
      - name: Generate New Password
        id: generate
        run: |
          NEW_PASSWORD=$(openssl rand -base64 32)
          echo "password=$NEW_PASSWORD" >> $GITHUB_OUTPUT
      
      - name: Update Database
        run: |
          mysql -h "${{ secrets.DB_HOST }}" \
            -u "${{ secrets.DB_USER }}" \
            -p"${{ secrets.DB_PASSWORD }}" \
            -e "ALTER USER 'dbuser'@'%' IDENTIFIED BY '${{ steps.generate.outputs.password }}';"
      
      - name: Update Key Vault
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
        run: |
          az keyvault secret set \
            --vault-name kv-company-prod \
            --name "DBPassword" \
            --value "${{ steps.generate.outputs.password }}"
      
      - name: Notify Team
        if: always()
        run: |
          echo "Password rotation completed"
```

### GitLab CI/CD Integration

```yaml
stages:
  - deploy

deploy_keyvault:
  stage: deploy
  image: hashicorp/terraform:latest
  
  variables:
    TF_ROOT: ${CI_PROJECT_DIR}/terraform
  
  script:
    - cd ${TF_ROOT}
    - terraform init
    - terraform plan -out=tfplan
    - terraform apply tfplan
  
  only:
    - main
  
  environment:
    name: production
```

## Disaster Recovery

### Backup Key Vault Configuration

```bash
#!/bin/bash

# Export all secrets (be careful with this!)
BACKUP_DIR="keyvault-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

az keyvault secret list \
  --vault-name kv-company-prod \
  --query "[].name" -o tsv | while read secret_name; do
    
    az keyvault secret show \
      --vault-name kv-company-prod \
      --name "$secret_name" \
      --query "value" -o tsv > "$BACKUP_DIR/$secret_name.txt"
done

# Compress and encrypt
tar czf - "$BACKUP_DIR" | gpg --symmetric --cipher-algo AES256 > "keyvault-backup.tar.gz.gpg"

# Upload to secure storage
az storage blob upload \
  --container-name backups \
  --name "keyvault-backup-$(date +%Y%m%d).tar.gz.gpg" \
  --file "keyvault-backup.tar.gz.gpg" \
  --account-name securebackupstg
```

### Restore from Backup

```bash
#!/bin/bash

# Download backup
az storage blob download \
  --container-name backups \
  --name "keyvault-backup-20240101.tar.gz.gpg" \
  --account-name securebackupstg \
  --file keyvault-backup.tar.gz.gpg

# Decrypt and extract
gpg --decrypt keyvault-backup.tar.gz.gpg | tar xz

# Restore secrets to new Keyvault
backup_dir="keyvault-backup-20240101"
for secret_file in "$backup_dir"/*.txt; do
    secret_name=$(basename "$secret_file" .txt)
    secret_value=$(cat "$secret_file")
    
    az keyvault secret set \
      --vault-name kv-company-prod-restore \
      --name "$secret_name" \
      --value "$secret_value"
done
```

### Soft Delete and Purge Recovery

```bash
# List deleted vaults
az keyvault list-deleted

# Recover a soft-deleted vault
az keyvault recover \
  --name kv-company-prod \
  --resource-group rg-keyvault-prod

# Permanently purge a vault
az keyvault purge --name kv-company-prod
```

## Compliance and Auditing

### Enable Audit Logging

```hcl
resource "azurerm_monitor_diagnostic_setting" "keyvault_audit" {
  name               = "keyvault-audit"
  target_resource_id = azurerm_key_vault.keyvault.id
  
  log_analytics_workspace_id = azurerm_log_analytics_workspace.compliance.id
  
  log {
    category = "AuditEvent"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 365
    }
  }
}
```

### Query Audit Logs

```bash
# View Key Vault access logs
az monitor log-analytics query \
  --workspace "log-workspace-id" \
  --analytics-query "AzureDiagnostics | where ResourceType == 'VAULTS' | project TimeGenerated, OperationName, CallerIPAddress"
```

## Next Steps

- Implement automated secret rotation
- Set up monitoring and alerts
- Configure network restrictions
- Implement RBAC for fine-grained access control
- Achieve compliance certifications (SOC 2, ISO 27001, etc.)
