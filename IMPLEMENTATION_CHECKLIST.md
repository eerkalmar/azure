# Implementation Checklist

Use this checklist to ensure you complete all necessary steps for deploying Azure Keyvault with GitHub Actions and Terraform.

## Pre-Deployment

- [ ] Review the complete tutorial in [KEYVAULT_DEPLOYMENT_GUIDE.md](./KEYVAULT_DEPLOYMENT_GUIDE.md)
- [ ] Understand the architecture in [ARCHITECTURE_AND_BEST_PRACTICES.md](./ARCHITECTURE_AND_BEST_PRACTICES.md)
- [ ] Ensure you have Azure CLI installed: `az --version`
- [ ] Ensure you have Git installed: `git --version`
- [ ] Have access to your Azure subscription as subscription owner
- [ ] Have admin access to your GitHub repository

## Step 1: Azure Setup

### Service Principal Creation
- [ ] Run: `az login`
- [ ] Get Subscription ID: `az account show --query "id" -o tsv`
- [ ] Create Service Principal: `az ad sp create-for-rbac --name "github-actions-sp" ...`
- [ ] Save output securely (Client ID, Client Secret, Tenant ID)
- [ ] Get Object ID: `az ad sp show --id <client-id> --query "id" -o tsv`
- [ ] Verify service principal has Contributor role on subscription

### Verification
- [ ] Service Principal appears in Azure AD → App registrations
- [ ] Service Principal has Contributor role on subscription level
- [ ] All 5 credential values are securely documented

## Step 2: GitHub Repository Setup

### Create Directory Structure
- [ ] Create `terraform/` directory
- [ ] Create `.github/workflows/` directory
- [ ] Verify `.gitignore` exists and includes `.terraform/`

### Copy Configuration Files
- [ ] Copy `terraform/main.tf`
- [ ] Copy `terraform/variables.tf`
- [ ] Copy `terraform/outputs.tf`
- [ ] Copy `terraform/terraform.tfvars`
- [ ] Copy `.github/workflows/deploy-keyvault.yml`

### GitHub Secrets Configuration
- [ ] Navigate to Settings → Secrets and variables → Actions
- [ ] Add `AZURE_CLIENT_ID`: (appId from service principal)
- [ ] Add `AZURE_CLIENT_SECRET`: (password from service principal)
- [ ] Add `AZURE_TENANT_ID`: (tenant from service principal)
- [ ] Add `AZURE_SUBSCRIPTION_ID`: (subscription ID)
- [ ] Add `AZURE_BACKEND_OBJECT_ID`: (object ID from service principal)
- [ ] Verify all 5 secrets are present and correctly set

## Step 3: Terraform Configuration

### Update terraform.tfvars
- [ ] Update `keyvault_name` to be globally unique
  - Format: `kv-companyname-env` or include timestamp
  - Contains only letters, numbers, and hyphens
  - Maximum 24 characters
- [ ] Verify `resource_group_name` is appropriate
- [ ] Check `location` matches your desired region
- [ ] Confirm `sku_name` is appropriate (standard for dev, premium for prod)

### Validate Configuration
- [ ] Run locally: `terraform init` (uses local state for testing)
- [ ] Run: `terraform validate`
- [ ] Run: `terraform fmt -check -recursive`
- [ ] Run: `terraform plan` with proper environment variables set
  - Set `TF_VAR_client_id`, `TF_VAR_client_secret`, etc. before running

## Step 4: Branch Protection (Recommended)

- [ ] Go to Settings → Branches
- [ ] Add rule for `main` branch
- [ ] Require pull request reviews before merging
- [ ] Require status checks to pass (Actions workflow)
- [ ] Dismiss stale PR approvals
- [ ] Require branches to be up to date before merging

## Step 5: Initial Deployment

### Create Feature Branch
- [ ] Create new branch: `git checkout -b feature/keyvault-deployment`
- [ ] Stage changes: `git add .`
- [ ] Commit changes: `git commit -m "Add Keyvault Terraform configuration"`

### Verify Workflow Triggers on PR
- [ ] Push branch: `git push origin feature/keyvault-deployment`
- [ ] Create Pull Request on GitHub
- [ ] Go to Actions tab and monitor workflow
- [ ] Verify workflow runs and generates plan
- [ ] Review plan output in PR comments
- [ ] Ensure plan shows correct resources to create

### Approve and Merge
- [ ] Review Terraform plan in PR
- [ ] Get approval from another team member (if required)
- [ ] Merge PR to main branch
- [ ] Go to Actions tab and monitor production deployment workflow
- [ ] Wait for workflow to complete successfully

## Step 6: Post-Deployment Verification

### Verify Azure Resources
- [ ] Check Azure Portal → Key Vaults
- [ ] Confirm Keyvault exists with correct name
- [ ] Verify location is correct
- [ ] Check resource group exists
- [ ] Verify access policies include service principal

### Verify Terraform State
- [ ] Run: `terraform state list`
- [ ] Verify output: `terraform output`
- [ ] Confirm all outputs match expected values
- [ ] Check: `terraform show` to view all resource details

### Verify Access
- [ ] Run: `az keyvault list --resource-group rg-keyvault-prod`
- [ ] Get Keyvault details: `az keyvault show --name <keyvault-name> --resource-group <rg-name>`

## Step 7: Remote State Setup (Production)

- [ ] Create resource group for state: `az group create --name rg-terraform-state --location "East US"`
- [ ] Create storage account: (follow BACKEND_SETUP.md)
- [ ] Create storage container for tfstate
- [ ] Get storage account key
- [ ] Create `terraform/backend.tf` with backend configuration
- [ ] Add GitHub secrets for backend access
- [ ] Run: `terraform init` to migrate state to remote
- [ ] Verify state file in Azure Storage

## Step 8: Add Initial Secrets

- [ ] Add example secret via Terraform or CLI
- [ ] Verify secret appears in Keyvault
- [ ] Test retrieving secret: `az keyvault secret show --vault-name <name> --name <secret-name>`

## Post-Deployment Tasks

### Security Hardening
- [ ] Enable purge protection on Keyvault (for production)
- [ ] Review and restrict access policies
- [ ] Set up network rules/firewall if needed
- [ ] Enable logging and monitoring
- [ ] Configure alerts for audit events

### Documentation
- [ ] Document custom environment-specific settings
- [ ] Create runbooks for common operations
- [ ] Document team members with Keyvault access
- [ ] Create backup procedures
- [ ] Document disaster recovery process

### Team Communication
- [ ] Share Keyvault URL with team
- [ ] Document how to add secrets
- [ ] Provide guide for applications to use Keyvault
- [ ] Set rotation schedule for long-lived secrets
- [ ] Define access request process

### Monitoring Setup
- [ ] Configure Key Vault diagnostics/logging
- [ ] Set up alert rules for suspicious activity
- [ ] Create dashboard to monitor Keyvault usage
- [ ] Set up notifications for failed operations

## Ongoing Maintenance

- [ ] **Weekly**: Monitor workflow executions
- [ ] **Monthly**: Review Keyvault access logs
- [ ] **Quarterly**: Rotate service principal secret (optional: `AZURE_CLIENT_SECRET`)
- [ ] **Quarterly**: Review and update access policies
- [ ] **Annually**: Plan capacity and cost optimization

## Troubleshooting

If you encounter issues, check:

- [ ] GitHub secrets are correctly set and not expired
- [ ] Service principal still has Contributor role on subscription
- [ ] Terraform files are properly formatted
- [ ] Keyvault name is globally unique
- [ ] Resource group name is correct
- [ ] Azure subscription ID is correct
- [ ] Service principal object ID is correct
- [ ] GitHub Actions logs show full error details
- [ ] Network connectivity to Azure is available
- [ ] Local Terraform plan works before expecting workflow to work

## Common Issues and Solutions

### "Keyvault name must be globally unique"
- [ ] Change name in `terraform.tfvars` to something more unique
- [ ] Include company name, project, environment, and random identifier

### "Authentication failed in GitHub Actions"
- [ ] Verify all 5 GitHub secrets are present
- [ ] Check secrets have correct values (no extra spaces)
- [ ] Confirm service principal still exists in Azure
- [ ] Verify service principal hasn't been deleted

### "Terraform plan/apply fails locally"
- [ ] Set required environment variables: `TF_VAR_*`
- [ ] Run: `terraform init` first
- [ ] Check Azure CLI is authenticated: `az account show`
- [ ] Verify file paths and permissions

### "Resource already exists"
- [ ] Change resource names to be unique
- [ ] Check if resource exists from previous attempt
- [ ] May need to import existing resource: `terraform import`

## Completion

- [ ] All boxes above are checked
- [ ] Keyvault is successfully deployed
- [ ] Terraform can manage Keyvault successfully
- [ ] GitHub Actions workflow runs successfully
- [ ] Team has access and documentation
- [ ] Monitoring is in place
- [ ] Backup procedures are documented

## Next Steps

1. **Immediate**: Test by adding/retrieving a secret
2. **This week**: Set up monitoring and alerts
3. **This month**: Enable remote state in Azure Storage
4. **This quarter**: Implement advanced security settings
5. **Ongoing**: Regularly review access and rotate secrets

---

Need help? See:
- Quick Start: [QUICKSTART.md](./QUICKSTART.md)
- Full Guide: [KEYVAULT_DEPLOYMENT_GUIDE.md](./KEYVAULT_DEPLOYMENT_GUIDE.md)
- Architecture: [ARCHITECTURE_AND_BEST_PRACTICES.md](./ARCHITECTURE_AND_BEST_PRACTICES.md)
- Advanced: [ADVANCED_USAGE.md](./ADVANCED_USAGE.md)
