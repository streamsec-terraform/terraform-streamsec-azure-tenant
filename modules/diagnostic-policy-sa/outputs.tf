output "sa_policy_assignment_ids" {
  description = "Map of subscription ID to Storage Account policy assignment ID."
  value = {
    for sub, assignment in azurerm_subscription_policy_assignment.sa_blob_diag : sub => assignment.id
  }
}
