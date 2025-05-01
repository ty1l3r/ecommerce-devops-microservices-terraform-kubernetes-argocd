#===============================================================================
# OUTPUTS DU MODULE EKS
# Description: Valeurs exportées par le module pour utilisation par d'autres modules
#===============================================================================

#-----------------------------------
# Informations de base du cluster
#-----------------------------------
output "cluster_name" {
  description = "Nom du cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint de l'API Kubernetes"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data pour l'authentification au cluster"
  value       = module.eks.cluster_certificate_authority_data
}

#-----------------------------------
# Informations réseau
#-----------------------------------
output "cluster_primary_security_group_id" {
  description = "ID du security group principal du cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "node_security_group_id" {
  description = "ID du security group des nœuds workers"
  value       = module.eks.node_security_group_id
}

#-----------------------------------
# Informations OIDC pour IAM Roles for Service Accounts
#-----------------------------------
output "cluster_oidc_issuer_url" {
  description = "URL de l'émetteur OIDC du cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider" {
  description = "URL du provider OIDC pour la configuration IRSA"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN du provider OIDC pour l'intégration IAM"
  value       = module.eks.oidc_provider_arn
}

#-----------------------------------
# Informations de stockage
#-----------------------------------
output "storage_class_name" {
  description = "Nom du StorageClass par défaut pour les volumes persistants"
  value       = kubernetes_storage_class.gp3.metadata[0].name
}