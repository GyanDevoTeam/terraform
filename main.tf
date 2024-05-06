provider "azurerm" {
  features {}
}

# Module for testing environment
module "testing" {
  source = "./testing"
}

# Module for acceptance environment
module "acceptance" {
  source = "./acceptance"
}

# Module for production environment
module "production" {
  source = "./production"
}