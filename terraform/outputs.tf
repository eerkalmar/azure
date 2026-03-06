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
