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

resource "hcp_vault_cluster_admin_token" "vault" {
  cluster_id = "vault-cluster"
}

data "hcp_vault_secrets_secret" "access_key" {
  app_name    = "root-aws-account-domain"
  secret_name = "ACCESS_KEY"
}

data "hcp_vault_secrets_secret" "secret_access_key" {
  app_name    = "root-aws-account-domain"
  secret_name = "SECRET_ACCESS_KEY"
}

provider "vault" {
  token     = hcp_vault_cluster_admin_token.vault.token
  address   = hcp_vault_cluster.vault.public_endpoint
  namespace = "admin"
}

resource "vault_policy" "up-bank" {
  name   = "up-bank"
  policy = file("policies/up-bank.hcl")
}

resource "vault_auth_backend" "aws" {
  type = "aws"
  path = "aws"
}

resource "vault_aws_auth_backend_role" "example" {
  backend                         = vault_auth_backend.aws.path
  role                            = "test-role"
  auth_type                       = "iam"
  bound_account_ids               = ["123456789012"]
  bound_vpc_ids                   = ["vpc-b61106d4"]
  bound_subnet_ids                = ["vpc-133128f1"]
  bound_iam_role_arns             = ["arn:aws:iam::123456789012:role/MyRole"]
  bound_iam_instance_profile_arns = ["arn:aws:iam::123456789012:instance-profile/MyProfile"]
  inferred_entity_type            = "ec2_instance"
  inferred_aws_region             = "us-east-1"
  token_ttl                       = 60
  token_max_ttl                   = 120
  token_policies                  = ["default", "up-bank"]
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

resource "vault_aws_secret_backend_role" "role" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "deploy"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
EOT
}