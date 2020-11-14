web_server_location       = "uksouth"
primary_rg                = "CON-RG-01"
resource_prefix           = "web-server"
web_server_address_space  = "192.0.0.0/16"
web_server_address_prefix = "192.0.0.0/24"
web_server_name           = "web"
environment               = "development"
web_server_count          = 2
web_server_subnet = {
    web-server = "192.0.0.0/24"
    AzureBastionSubnet = "192.0.1.0/24"
}

