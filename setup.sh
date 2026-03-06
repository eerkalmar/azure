#!/bin/bash
# GitHub Actions + Terraform + Azure Keyvault - Setup Script
# This script automates the initial setup process

set -e  # Exit on error

echo "================================================"
echo "Azure Keyvault GitHub Actions Setup"
echo "================================================"
echo ""

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install it from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "❌ Git not found. Please install it from: https://git-scm.com/"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites satisfied${NC}"
echo ""

# Step 1: Login to Azure
echo -e "${BLUE}Step 1: Logging in to Azure...${NC}"
az login
echo -e "${GREEN}✓ Logged in${NC}"
echo ""

# Get subscription info
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
TENANT_ID=$(az account show --query "tenantId" -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"
echo ""

# Step 2: Create Service Principal
echo -e "${BLUE}Step 2: Creating Service Principal...${NC}"
SP_NAME="github-actions-sp"
SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" --role "Contributor" --scopes /subscriptions/$SUBSCRIPTION_ID)

CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.appId')
CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.password')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenant')

echo -e "${GREEN}✓ Service Principal created${NC}"
echo "Client ID: $CLIENT_ID"
echo ""

# Step 3: Get Service Principal Object ID
echo -e "${BLUE}Step 3: Getting Service Principal Object ID...${NC}"
OBJECT_ID=$(az ad sp show --id $CLIENT_ID --query "id" -o tsv)
echo -e "${GREEN}✓ Object ID: $OBJECT_ID${NC}"
echo ""

# Step 4: Display summary and next steps
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "Add these GitHub Secrets to your repository:"
echo "Settings → Secrets and variables → Actions"
echo ""
echo "1. AZURE_CLIENT_ID"
echo "   Value: $CLIENT_ID"
echo ""
echo "2. AZURE_CLIENT_SECRET"
echo "   Value: $CLIENT_SECRET"
echo ""
echo "3. AZURE_TENANT_ID"
echo "   Value: $TENANT_ID"
echo ""
echo "4. AZURE_SUBSCRIPTION_ID"
echo "   Value: $SUBSCRIPTION_ID"
echo ""
echo "5. AZURE_BACKEND_OBJECT_ID"
echo "   Value: $OBJECT_ID"
echo ""

echo -e "${YELLOW}IMPORTANT: Copy these values securely!${NC}"
echo "They will not be displayed again."
echo ""

# Optional: Save to file
read -p "Save credentials to file? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    CREDS_FILE=".github-secrets.env"
    cat > "$CREDS_FILE" << EOF
# GitHub Secrets - Keep this file secure!
AZURE_CLIENT_ID=$CLIENT_ID
AZURE_CLIENT_SECRET=$CLIENT_SECRET
AZURE_TENANT_ID=$TENANT_ID
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_BACKEND_OBJECT_ID=$OBJECT_ID
EOF
    echo "✓ Credentials saved to $CREDS_FILE"
    echo "⚠️  Add this file to .gitignore to prevent accidental commits"
    echo "   echo '$CREDS_FILE' >> .gitignore"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Add the secrets above to your GitHub repository"
echo "2. Update terraform/terraform.tfvars with your desired values"
echo "3. Review the KEYVAULT_DEPLOYMENT_GUIDE.md for full instructions"
echo "4. Push your code to trigger the GitHub Actions workflow"
echo ""

# Optional: Create GitHub secrets via CLI
read -p "Set GitHub secrets via CLI? (requires gh CLI) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI (gh) not found"
        echo "Install from: https://cli.github.com/"
    else
        echo "Setting secrets in GitHub..."
        gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
        gh secret set AZURE_CLIENT_SECRET --body "$CLIENT_SECRET"
        gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
        gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
        gh secret set AZURE_BACKEND_OBJECT_ID --body "$OBJECT_ID"
        echo -e "${GREEN}✓ All secrets configured${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Setup complete! You're ready to deploy.${NC}"
