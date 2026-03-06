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
  name                        = var.keyvault_name
  location                    = azurerm_resource_group.keyvault_rg.location
  resource_group_name         = azurerm_resource_group.keyvault_rg.name
  tenant_id                   = var.tenant_id
  sku_name                    = var.sku_name
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

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
