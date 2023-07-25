variable "internal_domain" {
  type = string
}

variable "canonical_domains" {
  type = list(string)
}

variable "token" {
  type = string
}

variable "postgres_root_password" {
  type = string
}

locals {
  domains = var.canonical_domains
  credentials_yml_content = yamlencode({ 
  	"internal_domain": var.internal_domain
  	"postgres_root_password": var.postgres_root_password, 
	"domains": var.canonical_domains
  })
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.28"
    }
	tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
  }

  backend "s3" {
    bucket = "problog-tf-states"
    key = "INTERNAL_DOMAIN/terraform.tfstate"

    access_key = "BUCKET_ACCESS_KEY"
    secret_key = "BUCKET_SECRET_KEY"
    endpoint = "https://sgp1.digitaloceanspaces.com"
    region = "us-east-1"

    skip_credentials_validation = true
    skip_metadata_api_check = true
  }
}

provider "digitalocean" {
  token = var.token
}

provider "tls" {}
