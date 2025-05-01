#===============================================================================
# MODULE NAT GATEWAY - ACCÈS INTERNET SORTANT SÉCURISÉ
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module déploie des NAT Gateways dans chaque zone de
# disponibilité pour permettre:
# - Un accès Internet sortant pour les instances dans les sous-réseaux privés
# - Une haute disponibilité grâce à un déploiement multi-AZ
# - Une isolation des flux de trafic sortant par AZ
# - Une gestion optimisée des IPs Élastiques (EIPs)
#===============================================================================

#===============================================================================
# COMMONS
#===============================================================================
# Importation du module commun pour la cohérence du tagging
module "commons" {
  source       = "../commons"
  project_name = var.project_name
  environment  = var.environment
}

# Définition d'un préfixe de nommage standardisé
locals {
  name = "${var.project_name}-${var.environment}"
}

#===============================================================================
# NAT GATEWAY & EIP
#===============================================================================
# Allocation d'adresses IP Élastiques (EIPs) pour les NAT Gateways
# Créé une EIP par zone de disponibilité définie dans les variables
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"  # Spécifie que l'EIP est utilisée dans un contexte VPC

  tags = merge(module.commons.tags, {
    Name = "${local.name}-eip-${count.index + 1}"  # Nommage séquentiel
    AZ   = var.availability_zones[count.index]     # Tag pour identifier l'AZ associée
  })
}

# Déploiement des NAT Gateways dans les sous-réseaux publics
# Une NAT Gateway est déployée par zone de disponibilité pour la haute disponibilité
resource "aws_nat_gateway" "main" {
  count             = length(var.availability_zones)
  allocation_id     = aws_eip.nat[count.index].id         # Association avec l'EIP correspondante
  subnet_id         = var.public_subnet_ids[count.index]  # Placement dans le sous-réseau public de la même AZ
  connectivity_type = "public"                            # Type de connectivité: accès Internet complet

  tags = merge(module.commons.tags, {
    Name = "${local.name}-nat-${count.index + 1}"  # Nommage séquentiel
    AZ   = var.availability_zones[count.index]     # Tag pour identifier l'AZ associée
  })

  # S'assure que les EIPs sont créées avant les NAT Gateways
  depends_on = [aws_eip.nat]
}