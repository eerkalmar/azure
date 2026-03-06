#!/usr/bin/env pwsh
# GitHub Actions + Terraform + Azure Keyvault - Setup Script (PowerShell)
# This script automates the initial setup process on Windows

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Azure Keyvault GitHub Actions Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Blue

$prerequisites = @("az", "git")
$missing = @()

foreach ($tool in $prerequisites) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        $missing += $tool
    }
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing tools: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "Please install the missing tools and try again." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Prerequisites satisfied" -ForegroundColor Green
Write-Host ""

# Step 1: Login to Azure
Write-Host "Step 1: Logging in to Azure..." -ForegroundColor Blue
az login | Out-Null
Write-Host "✓ Logged in" -ForegroundColor Green
Write-Host ""

# Get subscription info
$SUBSCRIPTION_ID = az account show --query "id" -o tsv
$TENANT_ID = az account show --query "tenantId" -o tsv

Write-Host "Subscription ID: $SUBSCRIPTION_ID"
Write-Host "Tenant ID: $TENANT_ID"
Write-Host ""

# Step 2: Create Service Principal
Write-Host "Step 2: Creating Service Principal..." -ForegroundColor Blue
$SP_NAME = "github-actions-sp"
$SP_JSON = az ad sp create-for-rbac --name "$SP_NAME" --role "Contributor" --scopes "/subscriptions/$SUBSCRIPTION_ID" | ConvertFrom-Json

$CLIENT_ID = $SP_JSON.appId
$CLIENT_SECRET = $SP_JSON.password
$TENANT_ID = $SP_JSON.tenant

Write-Host "✓ Service Principal created" -ForegroundColor Green
Write-Host "Client ID: $CLIENT_ID"
Write-Host ""

# Step 3: Get Service Principal Object ID
Write-Host "Step 3: Getting Service Principal Object ID..." -ForegroundColor Blue
$OBJECT_ID = az ad sp show --id $CLIENT_ID --query "id" -o tsv
Write-Host "✓ Object ID: $OBJECT_ID" -ForegroundColor Green
Write-Host ""

# Step 4: Display summary and next steps
Write-Host "================================================" -ForegroundColor Blue
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Add these GitHub Secrets to your repository:" -ForegroundColor Cyan
Write-Host "Settings → Secrets and variables → Actions"
Write-Host ""

$secrets = @{
    "AZURE_CLIENT_ID" = $CLIENT_ID
    "AZURE_CLIENT_SECRET" = $CLIENT_SECRET
    "AZURE_TENANT_ID" = $TENANT_ID
    "AZURE_SUBSCRIPTION_ID" = $SUBSCRIPTION_ID
    "AZURE_BACKEND_OBJECT_ID" = $OBJECT_ID
}

$counter = 1
foreach ($key in $secrets.Keys) {
    Write-Host "$counter. $key" -ForegroundColor Yellow
    Write-Host "   Value: $($secrets[$key])"
    Write-Host ""
    $counter++
}

Write-Host "⚠️  IMPORTANT: Copy these values securely!" -ForegroundColor Yellow
Write-Host "They will not be displayed again."
Write-Host ""

# Optional: Save to file
$response = Read-Host "Save credentials to file? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    $credsFile = ".github-secrets.env"
    $content = @"
# GitHub Secrets - Keep this file secure!
AZURE_CLIENT_ID=$CLIENT_ID
AZURE_CLIENT_SECRET=$CLIENT_SECRET
AZURE_TENANT_ID=$TENANT_ID
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
AZURE_BACKEND_OBJECT_ID=$OBJECT_ID
"@
    
    Set-Content -Path $credsFile -Value $content
    Write-Host "✓ Credentials saved to $credsFile" -ForegroundColor Green
    Write-Host "⚠️  Add this file to .gitignore to prevent accidental commits" -ForegroundColor Yellow
    Write-Host "   echo '$credsFile' >> .gitignore"
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Blue
Write-Host "1. Add the secrets above to your GitHub repository"
Write-Host "2. Update terraform/terraform.tfvars with your desired values"
Write-Host "3. Review the KEYVAULT_DEPLOYMENT_GUIDE.md for full instructions"
Write-Host "4. Push your code to trigger the GitHub Actions workflow"
Write-Host ""

# Optional: Create GitHub secrets via CLI
$response = Read-Host "Set GitHub secrets via CLI? (requires gh CLI) (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "❌ GitHub CLI (gh) not found" -ForegroundColor Red
        Write-Host "Install from: https://cli.github.com/" -ForegroundColor Yellow
    }
    else {
        Write-Host "Setting secrets in GitHub..." -ForegroundColor Blue
        
        foreach ($key in $secrets.Keys) {
            gh secret set $key --body $secrets[$key]
            Write-Host "✓ Set $key" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Setup complete! You're ready to deploy." -ForegroundColor Green
