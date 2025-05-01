#===============================================================================
# OUTPUTS DU MODULE NAT GATEWAY
# Description: Valeurs exportées pour être utilisées par d'autres modules
#===============================================================================

output "nat_gateway_ids" {
  description = "Liste des IDs des NAT Gateways créées (une par zone de disponibilité)"
  value       = aws_nat_gateway.main[*].id
}

output "eip_ids" {
  description = "Liste des IDs des adresses IP Élastiques associées aux NAT Gateways"
  value       = aws_eip.nat[*].id
}