locals {
  web_server_location       = "northcentralus"
  web_server_rg             = "${terraform.workspace}-web-rg"
  resource_prefix           = "${terraform.workspace}-web-server"
  web_server_address_space  = "10.0.0.0/22"
  web_server_address_prefix = "10.0.1.0/24"
  web_server_name           = "${terraform.workspace}-web-01"
  environment               = "${terraform.workspace}"
}
