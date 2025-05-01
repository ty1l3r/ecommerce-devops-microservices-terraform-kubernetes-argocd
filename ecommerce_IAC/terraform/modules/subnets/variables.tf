#===============================================================================
# VARIABLES DU MODULE SUBNETS
# Description: Variables nécessaires pour la configuration des sous-réseaux
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

#-----------------------------------
# Variables d'infrastructure
#-----------------------------------
variable "vpc_id" {
  type        = string
  description = "ID du VPC dans lequel créer les sous-réseaux"
}

variable "public_route_table_id" {
  type        = string
  description = "ID de la table de routage publique pour les sous-réseaux publics"
  default     = null  # Pour permettre null pour les sous-réseaux privés
}

variable "cluster_name" {
  type        = string
  description = "Nom du cluster EKS pour les tags de découverte automatique"
}

#-----------------------------------
# Variables de configuration réseau
#-----------------------------------
variable "availability_zones" {
  type        = list(string)
  description = "Liste des zones de disponibilité AWS où déployer les sous-réseaux"
}

variable "subnets_cidr" {
  type        = list(string)
  description = "Liste des CIDR pour l'ensemble des sous-réseaux"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "Liste des blocs CIDR pour les sous-réseaux publics"
  default     = []
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "Liste des blocs CIDR pour les sous-réseaux privés"
  default     = []
}

variable "nat_gateway_ids" {
  type        = list(string)
  description = "Liste des IDs des NAT Gateways (une par zone de disponibilité)"
  default     = []
}

#-----------------------------------
# Variables de comportement
#-----------------------------------
variable "private" {
  type        = bool
  description = "Indique si les sous-réseaux à créer sont privés (true) ou publics (false)"
  default     = false
}