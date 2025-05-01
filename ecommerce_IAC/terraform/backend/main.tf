#===============================================================================
# CONFIGURATION DU BACKEND TERRAFORM S3
# Auteur: Tyler
# Dernière mise à jour: Mazrs 2025
#
# Ce fichier configure l'infrastructure nécessaire pour stocker l'état Terraform
# dans S3 avec verrouillage DynamoDB. Cette approche permet:
# - Un stockage persistant et sauvegardé de l'état Terraform
# - Un travail collaboratif via le verrouillage d'état
# - Une sécurisation des données d'état sensibles (chiffrement, accès privé)
#===============================================================================

# Définition du fournisseur AWS pour cette région spécifique
provider "aws" {
  region = var.aws_region
}

#===============================================================================
# STOCKAGE DE L'ÉTAT TERRAFORM
#===============================================================================
# Bucket S3 principal pour stocker le fichier d'état Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "red-project-production-2-tfstate"
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  # Dans un environnement de production, cette option devrait être définie sur true
  # pour protéger contre la suppression accidentelle du bucket
  lifecycle {
    prevent_destroy = false
  }
}

#===============================================================================
# CONFIGURATION DE SÉCURITÉ ET INTÉGRITÉ
#===============================================================================
# Activation du versionnement pour conserver l'historique des états et faciliter
# la récupération en cas de besoin
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Application du chiffrement côté serveur pour protéger les données sensibles
# contenues dans le fichier d'état
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Blocage de tout accès public au bucket pour éviter toute exposition accidentelle
# des données potentiellement sensibles contenues dans l'état Terraform
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#===============================================================================
# VERROUILLAGE D'ÉTAT TERRAFORM
#===============================================================================
# Table DynamoDB pour le verrouillage d'état, empêchant les modifications concurrentes
# et les conflits potentiels lors du travail en équipe
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "red-project-production-2-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"  # Mode de facturation adapté aux charges de travail variables
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}