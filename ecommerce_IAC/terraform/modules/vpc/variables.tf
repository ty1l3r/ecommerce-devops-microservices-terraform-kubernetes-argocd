#===============================================================================
# VARIABLES DU MODULE VPC
# Description: Variables nécessaires pour la configuration du VPC
#===============================================================================

#-----------------------------------
# Variables générales
#-----------------------------------
variable "project_name" {
  type        = string
  description = "Nom du projet pour le tagging des ressources"
}

variable "environment" {
  type        = string
  description = "Environnement (dev, staging, prod) pour la séparation des ressources"
}

variable "region" {
  type        = string
  default     = "eu-west-3"
  description = "Région AWS (Paris par défaut)"
}

variable "cluster_name" {
  type        = string
  description = "Nom standardisé du cluster EKS"
}

#-----------------------------------
# Variables réseau
#-----------------------------------
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block pour définir la plage d'adresses IP du VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "Liste des zones de disponibilité à utiliser"
}

variable "private_subnets_cidr" {
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  description = "Blocs CIDR pour les sous-réseaux privés"
}

variable "public_subnets_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "Blocs CIDR pour les sous-réseaux publics"
}

#-----------------------------------
# Variables Velero
#-----------------------------------
variable "velero_provider" {
  type        = string
  default     = "aws"
  description = "Provider pour Velero (aws, azure, gcp)"
}

variable "velero_backup_retention_days" {
  type        = number
  default     = 30
  description = "Nombre de jours de rétention des backups Velero"
}

variable "velero_schedule" {
  type        = string
  default     = "0 */6 * * *" # Toutes les 6 heures
  description = "Schedule des backups Velero (format cron)"
}

variable "velero_included_namespaces" {
  type        = list(string)
  default     = ["*"]  # Tous les namespaces
  description = "Liste des namespaces à sauvegarder"
}