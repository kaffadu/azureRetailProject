provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.azure_region
}

resource "azurerm_container_registry" "acr" {
    name                = var.acr_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Basic"
    admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
    name                = "microservices-demo-aks"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = "microservices-demo"

    default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    }

    identity {
        type = "SystemAssigned"
    }
}


# Try to give permissions, to let the AKR access the ACR

# Data block to reference an existing service principal by name
data "azuread_service_principal" "github-actions-sp" {
    display_name = "github-actions-sp"
}

# Assign the AcrPull role to the existing service principal 'github-actions-sp'
resource "azurerm_role_assignment" "acrpull_role" {
    scope                = azurerm_container_registry.acr.id
    role_definition_name = "AcrPull"
    principal_id         = data.azuread_service_principal.github-actions-sp.object_id
    skip_service_principal_aad_check = true
}



# Data block to reference the subscription
data "azurerm_subscription" "primary" {}

# Grant the Owner role to the service principal at the subscription level
resource "azurerm_role_assignment" "sp_owner" {
    principal_id         = "561c1289-280d-4344-9eeb-79d032074744"  # Service principal object ID
    role_definition_name = "Owner"
    scope                = data.azurerm_subscription.primary.id
}


# # Data block to reference the subscription
# data "azurerm_subscription" "primary" {}

# # Grant the User Access Administrator role to the service principal at the subscription level
# resource "azurerm_role_assignment" "sp_user_access_admin" {
#   principal_id         = "561c1289-280d-4344-9eeb-79d032074744"  # Service principal object ID
#   role_definition_name = "User Access Administrator"
#   scope                = data.azurerm_subscription.primary.id
# }