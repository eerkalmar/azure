# Azure Keyvault Deployment with GitHub Actions and Terraform

This repository contains a complete, production-ready solution for deploying Azure Key Vault using Terraform and GitHub Actions CI/CD.

## 📋 Quick Links

- **🚀 [Quick Start Guide](./QUICKSTART.md)** - Get started in 5 minutes
- **📖 [Complete Tutorial](./KEYVAULT_DEPLOYMENT_GUIDE.md)** - Comprehensive step-by-step guide
- **🏗️ [Architecture & Best Practices](./ARCHITECTURE_AND_BEST_PRACTICES.md)** - Understand the design
- **🔧 [Advanced Usage Guide](./ADVANCED_USAGE.md)** - Advanced scenarios and integrations
- **✅ [Implementation Checklist](./IMPLEMENTATION_CHECKLIST.md)** - Track your progress
- **💾 [Remote State Setup](./terraform/BACKEND_SETUP.md)** - Configure state in Azure Storage

## What's Included

```
azure/
├── README.md                              # This file
├── QUICKSTART.md                          # 5-minute quick start
├── KEYVAULT_DEPLOYMENT_GUIDE.md          # Complete tutorial
├── ARCHITECTURE_AND_BEST_PRACTICES.md    # Architecture guide
├── ADVANCED_USAGE.md                     # Advanced scenarios
├── IMPLEMENTATION_CHECKLIST.md           # Progress tracking
├── setup.sh                              # Auto setup script (Bash)
├── setup.ps1                             # Auto setup script (PowerShell)
│
├── terraform/
│   ├── main.tf                           # Keyvault resource definition
│   ├── variables.tf                      # Input variables
│   ├── outputs.tf                        # Output values
│   ├── terraform.tfvars                  # Variable values
│   └── BACKEND_SETUP.md                  # Remote state configuration
│
└── .github/
    └── workflows/
        └── deploy-keyvault.yml           # GitHub Actions workflow
```

## 🎯 What This Solution Does

Automates the deployment of Azure Key Vault with:

✅ **Infrastructure as Code**: Terraform manages all resources  
✅ **CI/CD Pipeline**: GitHub Actions handles deployment automatically  
✅ **Plan & Apply**: Review changes in PRs before production deployment  
✅ **Remote State**: Azure Storage backend for team collaboration  
✅ **Security**: Service principal authentication with minimal permissions  
✅ **Best Practices**: Production-ready configuration and monitoring  

## 🚀 Getting Started

### 1. Choose Your Path

**→ I want to deploy immediately** (5 minutes)
- Read [QUICKSTART.md](./QUICKSTART.md)
- Run `setup.sh` or `setup.ps1`
- Review the plan in your PR
- Merge to deploy

**→ I want to understand everything** (30 minutes)
- Read [KEYVAULT_DEPLOYMENT_GUIDE.md](./KEYVAULT_DEPLOYMENT_GUIDE.md)
- Review [ARCHITECTURE_AND_BEST_PRACTICES.md](./ARCHITECTURE_AND_BEST_PRACTICES.md)
- Manually perform setup steps
- Deploy with full understanding

**→ I want to handle advanced scenarios** (1+ hour)
- Start with [KEYVAULT_DEPLOYMENT_GUIDE.md](./KEYVAULT_DEPLOYMENT_GUIDE.md)
- Review [ADVANCED_USAGE.md](./ADVANCED_USAGE.md)
- Set up remote state with [BACKEND_SETUP.md](./terraform/BACKEND_SETUP.md)
- Configure monitoring and recovery

### 2. Prerequisites

- Azure subscription with appropriate permissions
- GitHub repository (public or private)
- Azure CLI: `curl https://aka.ms/get-azure-cli | bash`
- Git: `https://git-scm.com/download`
- (Optional) Terraform CLI locally for testing

### 3. One-Time Setup

```bash
# For Linux/macOS
chmod +x setup.sh
./setup.sh

# For Windows PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup.ps1
```

Or follow the manual steps in [QUICKSTART.md](./QUICKSTART.md).

### 4. Deploy

```bash
# Create feature branch
git checkout -b feature/keyvault-deployment

# Commit Terraform files (already included)
git add .
git commit -m "Deploy Keyvault with Terraform"
git push origin feature/keyvault-deployment

# Create PR, review plan, merge to main
# GitHub Actions automatically deploys to production!
```

## 📊 Architecture Overview

```
GitHub Actions Workflow
    ↓
Creates/Updates Terraform
    ↓
Authenticates with Service Principal
    ↓
Deploys to Azure
    ├── Resource Group
    ├── Key Vault
    └── Access Policies
    ↓
Stores State in Azure Storage (optional)
```

## 🔒 Security Features

- **Service Principal Auth**: Limited credentials for automation
- **GitHub Secrets**: Encrypted credential storage
- **Branch Protection**: Require reviews before production deployment
- **Plan Review**: See changes before they're applied
- **State Encryption**: Terraform state encrypted in Azure Storage
- **Audit Logging**: Track all Key Vault access and changes

## 📁 File Structure Explained

### Terraform Files

| File | Purpose |
|------|---------|
| `main.tf` | Defines the Key Vault and related resources |
| `variables.tf` | Declares input variables with defaults |
| `outputs.tf` | Exports Key Vault details (URI, name, ID) |
| `terraform.tfvars` | Sets variable values (customize this) |

### GitHub Actions

| File | Purpose |
|------|---------|
| `.github/workflows/deploy-keyvault.yml` | Defines the CI/CD pipeline |

## 🔧 Customization

### Change Key Vault Name

Edit `terraform/terraform.tfvars`:
```hcl
keyvault_name = "kv-my-company-prod"  # Must be globally unique
```

### Change Region

Edit `terraform/terraform.tfvars`:
```hcl
location = "West Europe"  # Change to your preferred region
```

### Change Resource Group

Edit `terraform/terraform.tfvars`:
```hcl
resource_group_name = "rg-my-keyvault"
```

### Add More Secrets

Edit `terraform/main.tf` in the Keyvault resource:
```hcl
resource "azurerm_key_vault_secret" "my_secret" {
  name         = "MySecret"
  value        = var.my_secret_value
  key_vault_id = azurerm_key_vault.keyvault.id
}
```

## 📚 Documentation

| Document | Content |
|----------|---------|
| [QUICKSTART.md](./QUICKSTART.md) | 5-minute setup guide |
| [KEYVAULT_DEPLOYMENT_GUIDE.md](./KEYVAULT_DEPLOYMENT_GUIDE.md) | Complete step-by-step tutorial |
| [ARCHITECTURE_AND_BEST_PRACTICES.md](./ARCHITECTURE_AND_BEST_PRACTICES.md) | Design patterns and best practices |
| [ADVANCED_USAGE.md](./ADVANCED_USAGE.md) | Advanced scenarios and integrations |
| [IMPLEMENTATION_CHECKLIST.md](./IMPLEMENTATION_CHECKLIST.md) | Progress tracking checklist |
| [terraform/BACKEND_SETUP.md](./terraform/BACKEND_SETUP.md) | Remote state configuration |

## 🧪 Testing Locally

Before deploying via GitHub Actions, test locally:

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Create a plan (requires Azure CLI authentication)
az login
export TF_VAR_client_id="your-client-id"
export TF_VAR_client_secret="your-client-secret"
export TF_VAR_subscription_id="your-subscription-id"
export TF_VAR_tenant_id="your-tenant-id"
export TF_VAR_service_principal_object_id="your-object-id"

terraform plan

# Review the plan, then apply
terraform apply
```

## ❌ Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Keyvault name not unique" | Change name in `terraform.tfvars` to something unique |
| "Authentication failed" | Check GitHub secrets are correctly set |
| "State locked" | Wait or use `terraform force-unlock` |
| "Access denied" | Verify service principal has Contributor role |

For more troubleshooting, see:
- [KEYVAULT_DEPLOYMENT_GUIDE.md - Troubleshooting](./KEYVAULT_DEPLOYMENT_GUIDE.md#troubleshooting)
- [ARCHITECTURE_AND_BEST_PRACTICES.md - Troubleshooting Matrix](./ARCHITECTURE_AND_BEST_PRACTICES.md#troubleshooting-matrix)

## 📞 Getting Help

1. **Quick issues**: Check [IMPLEMENTATION_CHECKLIST.md](./IMPLEMENTATION_CHECKLIST.md)
2. **Setup problems**: Review [QUICKSTART.md](./QUICKSTART.md)
3. **How-to questions**: See [ADVANCED_USAGE.md](./ADVANCED_USAGE.md)
4. **Design questions**: Read [ARCHITECTURE_AND_BEST_PRACTICES.md](./ARCHITECTURE_AND_BEST_PRACTICES.md)

## 🔄 Next Steps

After successful deployment:

1. **Add Secrets**: Store sensitive data in Key Vault
   ```bash
   az keyvault secret set --vault-name <name> --name MySecret --value MyValue
   ```

2. **Use in Applications**: Reference secrets from your apps
   ```python
   from azure.keyvault.secrets import SecretClient
   client = SecretClient("https://<vault>.vault.azure.net", credential)
   secret = client.get_secret("MySecret")
   ```

3. **Enable Monitoring**: Set up alerts and logging
4. **Implement Rotation**: Automate secret rotation
5. **Multi-Environment**: Create dev, staging, prod environments

See [ADVANCED_USAGE.md](./ADVANCED_USAGE.md) for detailed examples.

## 🎓 Learning Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Terraform State Management](https://www.terraform.io/language/state)

## 📋 Contents Summary

```
├── Documentation Files (7 files)
│   ├── README.md                          ✓ Main guide (you are here)
│   ├── QUICKSTART.md                      ✓ 5-minute setup
│   ├── KEYVAULT_DEPLOYMENT_GUIDE.md      ✓ Complete tutorial
│   ├── ARCHITECTURE_AND_BEST_PRACTICES.md ✓ Architecture guide
│   ├── ADVANCED_USAGE.md                 ✓ Advanced scenarios
│   ├── IMPLEMENTATION_CHECKLIST.md       ✓ Progress tracking
│   └── terraform/BACKEND_SETUP.md        ✓ Remote state
│
├── Setup Scripts (2 files)
│   ├── setup.sh                 ✓ Linux/macOS automation
│   └── setup.ps1                ✓ Windows PowerShell
│
├── Terraform Configuration (4 files)
│   ├── terraform/main.tf        ✓ Key Vault definition
│   ├── terraform/variables.tf   ✓ Input variables
│   ├── terraform/outputs.tf     ✓ Output values
│   └── terraform/terraform.tfvars ✓ Configuration values
│
└── GitHub Actions (1 file)
    └── .github/workflows/deploy-keyvault.yml ✓ CI/CD pipeline
```

## ⚠️ Important Security Notes

1. **Never commit secrets** to the repository
2. **Rotate service principal secrets** every 90 days
3. **Use branch protection** on main branch
4. **Enable purge protection** on production Key Vaults
5. **Audit access regularly** to Key Vault
6. **Use managed identities** when possible instead of service principals
7. **Enable logging** for all Key Vault operations

## 📄 License

Feel free to use this solution as a template for your organization.

## 🤝 Contributing

Have improvements? Create an issue or pull request to share!

---

**Ready to deploy?** Start with [QUICKSTART.md](./QUICKSTART.md) or [KEYVAULT_DEPLOYMENT_GUIDE.md](./KEYVAULT_DEPLOYMENT_GUIDE.md)!
