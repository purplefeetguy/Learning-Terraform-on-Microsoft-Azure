provider "azurerm" {
    version         = "1.27.0"
    client_id       = "e5653f3d-a55e-474d-8386-c511590722e8"
    client_secret   = "IA72SU=wUdlqeJ[:tilteE-pNICuXe41"
    tenant_id       = "b82a4829-cdd4-48de-b142-985c68d41b4c"
    subscription_id = "0b55b4c7-3322-4eb8-988a-0cda8f823217"
}

resource "azurerm_resource_group" "web_server_rg" {
    name     = "web-rg"
    location = "westus2"
}
