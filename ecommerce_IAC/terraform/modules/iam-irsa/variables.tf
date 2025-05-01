#-------------------------------------------------------------------------------
# VARIABLES GÉNÉRALES
#-------------------------------------------------------------------------------
variable "project_name" {
  type        = string
  description = "Nom du projet pour préfixer les ressources créées"
}

variable "environment" {
  type        = string
  description = "Environnement de déploiement (production, staging, development)"
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "La valeur de environment doit être 'production', 'staging' ou 'development'."
  }
}

#-------------------------------------------------------------------------------
# VARIABLES EKS OIDC
#-------------------------------------------------------------------------------
variable "eks_oidc_provider" {
  type        = string
  description = "URL du provider OIDC EKS (sans le protocole https://)"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "ARN du provider OIDC EKS utilisé pour l'authentification des services accounts"
}

#-------------------------------------------------------------------------------
# VARIABLES STOCKAGE S3
#-------------------------------------------------------------------------------
variable "logs_bucket_arn" {
  description = "ARN du bucket S3 pour le stockage des logs d'application"
  type        = string
}

variable "backup_bucket_arn" {
  description = "ARN du bucket S3 pour le stockage des sauvegardes"
  type        = string
}

variable "tf_state_bucket" {
  description = "Nom du bucket S3 contenant l'état Terraform"
  type        = string
}

#-------------------------------------------------------------------------------
# VARIABLES KUBERNETES SERVICE ACCOUNTS
#-------------------------------------------------------------------------------
variable "velero_namespace" {
  description = "Namespace Kubernetes où est déployé Velero"
  type        = string
  default     = "velero"
}

variable "velero_service_account" {
  description = "Nom du service account Kubernetes utilisé par Velero"
  type        = string
  default     = "velero"
}

#-------------------------------------------------------------------------------
# VARIABLES DU MODULE IAM IRSA
#-------------------------------------------------------------------------------

variable "project_name" {
  description = "Nom du projet utilisé pour préfixer les ressources"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
}

variable "eks_oidc_provider" {
  description = "URL du fournisseur OIDC associé au cluster EKS (sans le protocole https://)"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN du fournisseur OIDC associé au cluster EKS"
  type        = string
}

variable "logs_bucket_arn" {
  description = "ARN du bucket S3 utilisé pour stocker les logs"
  type        = string
}

variable "backup_bucket_arn" {
  description = "ARN du bucket S3 utilisé pour stocker les backups"
  type        = string
}

variable "velero_namespace" {
  description = "Namespace Kubernetes où est déployé Velero"
  type        = string
  default     = "velero"
}

variable "velero_service_account" {
  description = "Nom du service account utilisé par Velero"
  type        = string
  default     = "velero"
}