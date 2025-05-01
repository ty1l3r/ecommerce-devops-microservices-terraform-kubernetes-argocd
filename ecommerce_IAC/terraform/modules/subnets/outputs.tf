#===============================================================================
# OUTPUTS DU MODULE SUBNETS
# Description: Valeurs exportées pour être utilisées par d'autres modules
#===============================================================================

output "public_subnet_ids" {
  description = "Liste des IDs des sous-réseaux publics créés"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Liste des IDs des sous-réseaux privés créés"
  value       = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  description = "Liste des IDs des tables de routage privées créées pour chaque AZ"
  value       = aws_route_table.private[*].id
}