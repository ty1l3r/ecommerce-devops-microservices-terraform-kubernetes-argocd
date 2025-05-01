#===============================================================================
# VARIABLES DU MODULE EKS
# Description: Variables nécessaires pour la configuration du cluster Kubernetes
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
  description = "Environnement (production, staging, development)"
}

variable "cluster_name" {
  type        = string
  description = "Nom standardisé du cluster EKS"
}

#-----------------------------------
# Variables réseau
#-----------------------------------
variable "vpc_config" {
  description = "Configuration du VPC pour le déploiement du cluster"
  type = object({
    vpc_id     = string  # ID du VPC où déployer le cluster
    subnet_ids = list(string)  # IDs des sous-réseaux (de préférence privés)
  })
}

variable "cluster_public_access_cidrs" {
  type        = list(string)
  description = "Liste des CIDR autorisés à accéder à l'API Kubernetes"
  default     = ["0.0.0.0/0"]  # Ouvert par défaut, à restreindre en production
}

variable "cluster_service_ipv4_cidr" {
  type        = string
  description = "CIDR pour les ClusterIPs des services Kubernetes"
  default     = "172.20.0.0/16"  # Plage distincte du CIDR du VPC
}

#-----------------------------------
# Variables de cluster
#-----------------------------------
variable "cluster_version" {
  type        = string
  description = "Version de Kubernetes à déployer"
  default     = "1.28"  # Version stable récente
}

variable "eks_admins_iam_role_arn" {
  description = "ARN du rôle IAM pour l'accès administrateur au cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN du rôle IAM pour les nœuds worker EKS"
  type        = string
}

#-----------------------------------
# Variables des nœuds workers
#-----------------------------------
variable "instance_types" {
  type        = list(string)
  description = "Types d'instances EC2 pour les nœuds workers"
  default     = ["t3.large"]  # Bon équilibre entre coût et performances
}

variable "node_volume_size" {
  type        = number
  description = "Taille (GB) du volume EBS principal des nœuds"
  default     = 18  # Suffisant pour OS, Docker images et journaux système
}

variable "nodes_min_size" {
  type        = number
  description = "Nombre minimum de nœuds (scaling automatique)"
  default     = 2  # Minimum pour la haute disponibilité
}

variable "nodes_max_size" {
  type        = number
  description = "Nombre maximum de nœuds (scaling automatique)"
  default     = 2  # Limité pour contrôle des coûts
}

variable "nodes_desired_size" {
  type        = number
  description = "Nombre souhaité de nœuds au démarrage"
  default     = 2  # Configuration initiale standard
}

#-----------------------------------
# Variables de stockage
#-----------------------------------
variable "mongodb_storage_class" {
  description = "Configuration du StorageClass pour MongoDB"
  type = object({
    name = string  # Nom de la StorageClass (ex: gp3-encrypted)
    type = string  # Type de volume (ex: gp3)
  })
}
