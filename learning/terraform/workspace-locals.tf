locals {
  web_server_location       = "northcentralus"
  web_server_rg             = "${var.environment}-web-rg"
  resource_prefix           = "${var.environment}-web-server"
  web_server_address_space  = "10.0.0.0/22"
  web_server_address_prefix = "10.0.1.0/24"
  web_server_name           = "${var.environment}-web-01"
  environment               = "${terraform.workspace}"
}
