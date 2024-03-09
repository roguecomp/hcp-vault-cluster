provider "hcp" {}

resource "hcp_hvn" "vault" {
  hvn_id         = "hvn-vault"
  cloud_provider = "aws"
  region         = "ap-southeast-2"
}

resource "hcp_vault_cluster" "example" {
  cluster_id = "vault-cluster"
  hvn_id     = hcp_hvn.vault.hvn_id
  tier       = "dev"
  public_endpoint = true
#   lifecycle {
#     prevent_destroy = true
#   }
}