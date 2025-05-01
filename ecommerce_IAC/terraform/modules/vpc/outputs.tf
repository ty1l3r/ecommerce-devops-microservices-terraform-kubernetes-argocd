#===============================================================================
# OUTPUTS DU MODULE VPC
#===============================================================================

output "vpc_id" {
  description = "L'identifiant unique du VPC créé"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "Le bloc CIDR du VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_route_table_id" {
  description = "L'identifiant de la table de routage publique"
  value       = aws_route_table.public.id
}

