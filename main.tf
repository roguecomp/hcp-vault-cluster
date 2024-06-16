terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.83.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.25.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.29.0"
    }
  }
}

provider "hcp" {}

resource "hcp_hvn" "vault" {
  hvn_id         = "hvn-vault"
  cloud_provider = "aws"
  region         = "ap-southeast-2"
}

resource "hcp_vault_cluster" "vault" {
  cluster_id      = "vault-cluster"
  hvn_id          = hcp_hvn.vault.hvn_id
  tier            = var.cluster_tier
  public_endpoint = true
  
  #   lifecycle {
  #     prevent_destroy = true
  #   }
}

data "hcp_vault_secrets_secret" "access_key" {
  app_name    = "aws-account"
  secret_name = "ACCESS_KEY"
}

data "hcp_vault_secrets_secret" "secret_access_key" {
  app_name    = "aws-account"
  secret_name = "SECRET_ACCESS_KEY"
}

# provider "cloudflare" {
#   api_token = data.hcp_vault_secrets_secret.cloudflare_token.secret_value
# }

# data "cloudflare_zones" "domain" {
#   filter {
#     name = "vishnukap.com"
#   }
# }

# resource "cloudflare_record" "vault" {
#   zone_id = data.cloudflare_zones.domain.zones[0].id
#   name    = "vault"
#   value   = hcp_vault_cluster.vault.vault_proxy_endpoint_url
#   type    = "CNAME"
#   ttl     = 1
#   proxied = true
# }

output "vault_public_endpoint_url" {
  value = hcp_vault_cluster.vault.vault_public_endpoint_url
}

# output "vault_proxy_endpoint_url" {
#   value = hcp_vault_cluster.vault.vault_proxy_endpoint_url
# }

# output "zone_id" {
#   value = data.cloudflare_zones.domain.zones[0].id
# }