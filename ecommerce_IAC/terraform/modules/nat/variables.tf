#===============================================================================
# VARIABLES DU MODULE NAT GATEWAY
# Description: Variables nécessaires pour la configuration des NAT Gateways
#===============================================================================

#-----------------------------------
# Variables d'infrastructure
#-----------------------------------
variable "availability_zones" {
  description = "Liste des zones de disponibilité où déployer les NAT Gateways"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Liste des IDs des sous-réseaux publics où placer les NAT Gateways"
  type        = list(string)
}

#-----------------------------------
# Variables générales
#-----------------------------------
variable "project_name" {
  description = "Nom du projet pour le tagging des ressources"
  type        = string
}

variable "environment" {
  description = "Environnement (production, staging, development)"
  type        = string
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "L'environnement doit être 'production', 'staging' ou 'development'"
  }
}

variable "vpc_id" {
  type        = string
  description = "ID du VPC"
}