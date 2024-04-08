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
  tier            = "dev"
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

provider "vault" {
  token     = hcp_vault_cluster_admin_token.vault.token
  address   = hcp_vault_cluster.vault.vault_public_endpoint_url
  namespace = "admin"
}

resource "hcp_vault_cluster_admin_token" "vault" {
  cluster_id = "vault-cluster"

  depends_on = [hcp_vault_cluster.vault]
}

resource "vault_policy" "up-bank" {
  name   = "up-bank"
  policy = file("policies/up-bank.hcl")
}

resource "vault_mount" "kv" {
  path = "kv"
  type = "kv-v2"
}

resource "vault_aws_secret_backend" "aws" {
  access_key = data.hcp_vault_secrets_secret.access_key.secret_value
  secret_key = data.hcp_vault_secrets_secret.secret_access_key.secret_value
  path       = "aws"
}

#resource "vault_aws_secret_backend_role" "role" {
#  backend         = vault_aws_secret_backend.aws.path
#  name            = "deploy"
#  credential_type = "iam_user"
#
#  policy_document = <<EOT
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Action": "iam:*",
#      "Resource": "*"
#    }
#  ]
#}
#EOT
#}
