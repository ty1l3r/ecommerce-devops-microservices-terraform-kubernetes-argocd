#===============================================================================
# VARIABLES DU MODULE S3
# Description: Variables nécessaires pour la configuration des buckets S3
#===============================================================================

#-----------------------------------
# Variables générales
#-----------------------------------
variable "project_name" {
  type        = string
  description = "Nom du projet pour le tagging des ressources"
  default     = "red-project"
}

variable "environment" {
  type        = string
  description = "Environnement déployé (production, staging, development)"
  default     = "production"
}

#-----------------------------------
# Variables de rétention des données
#-----------------------------------
variable "retention_days" {
  description = "Configuration des durées de rétention par type de données (en jours)"
  type = object({
    backup = object({
      mongodb = number  # Durée de conservation des sauvegardes MongoDB
      velero  = number  # Durée de conservation des sauvegardes Kubernetes via Velero
    })
    logs = object({
      audit    = number  # Logs d'audit pour la conformité et la sécurité
      security = number  # Logs de sécurité (tentatives d'accès, alertes)
      access   = number  # Logs d'accès des applications et API
      events   = number  # Événements système et applicatifs
    })
  })
}