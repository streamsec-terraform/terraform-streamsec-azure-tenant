output "kv_policy_assignment_ids" {
  description = "Map of subscription ID to Key Vault policy assignment ID."
  value = {
    for sub, assignment in azurerm_subscription_policy_assignment.kv_diag : sub => assignment.id
  }
}
