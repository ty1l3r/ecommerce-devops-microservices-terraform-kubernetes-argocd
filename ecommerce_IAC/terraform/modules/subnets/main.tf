#===============================================================================
# MODULE SUBNETS - CONFIGURATION DES SOUS-RÉSEAUX
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module configure l'infrastructure de sous-réseaux pour la 
# plateforme e-commerce, incluant:
# - Sous-réseaux publics pour les services exposés (load balancers, bastions)
# - Sous-réseaux privés pour les workloads sensibles (EKS, bases de données)
# - Tables de routage personnalisées avec routes via NAT Gateways
# - Tags spéciaux pour l'intégration avec EKS et AWS Load Balancers
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
# SUBNETS
#===============================================================================

# Sous-réseaux publics - Exposés à Internet via Internet Gateway
# Ces sous-réseaux hébergent les load balancers et les points d'accès externes
resource "aws_subnet" "public" {
  count             = length(var.public_subnets_cidr)
  vpc_id            = var.vpc_id
  cidr_block        = var.public_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  # Attribution automatique d'IPs publiques aux instances lancées dans ce sous-réseau
  map_public_ip_on_launch = true

  # Tags incluant les annotations spéciales pour l'intégration AWS EKS et ELB
  tags = merge(module.commons.tags, {
    Name                                        = "${local.name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"  # Indique à AWS que ce sous-réseau peut héberger des ELB
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # Permet au cluster EKS d'identifier ce sous-réseau
    Type                                        = "Public"  # Facilite l'identification du type de sous-réseau
    AZ                                          = var.availability_zones[count.index]  # Zone de disponibilité
  })
}

# Sous-réseaux privés - Isolés d'Internet, accès sortant via NAT Gateways
# Ces sous-réseaux hébergent les pods EKS et autres ressources protégées
resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  # Tags avec annotations spéciales pour les load balancers internes
  tags = merge(module.commons.tags, {
    Name                                        = "${local.name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"  # Indique que ce sous-réseau peut héberger des ELB internes
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # Association au cluster EKS
    Type                                        = "Private"  # Type de sous-réseau pour identification
  })
}

#===============================================================================
# ROUTAGE
#===============================================================================

# Tables de routage pour les sous-réseaux privés (une par zone de disponibilité)
# Permet de définir des routes différentes selon la zone pour optimiser les coûts et la latence
resource "aws_route_table" "private" {
  count  = length(var.private_subnets_cidr)
  vpc_id = var.vpc_id

  tags = merge(module.commons.tags, {
    Name = "${local.name}-rt-private-${count.index + 1}"
    AZ   = var.availability_zones[count.index]  # Zone associée à cette table
  })
}

# Route par défaut pour les sous-réseaux privés vers Internet via NAT Gateway
# Chaque sous-réseau privé utilise la NAT Gateway dans sa propre zone de disponibilité
resource "aws_route" "private_nat" {
  count                  = length(var.private_subnets_cidr)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"  # Route tout le trafic sortant
  nat_gateway_id         = var.nat_gateway_ids[count.index]  # Via la NAT Gateway correspondante
}

#===============================================================================
# ASSOCIATIONS DE TABLE DE ROUTAGE
#===============================================================================

# Association des sous-réseaux publics à la table de routage publique (définie dans le module VPC)
resource "aws_route_table_association" "public" {
  count          = var.private ? 0 : length(var.public_subnets_cidr)  # Seulement si ce n'est pas un sous-réseau privé
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = var.public_route_table_id  # Table de routage avec la route vers Internet Gateway
}

# Association des sous-réseaux privés à leurs tables de routage respectives
resource "aws_route_table_association" "private" {
  count          = var.private ? length(var.private_subnets_cidr) : 0  # Seulement si c'est un sous-réseau privé
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id  # Chaque sous-réseau a sa propre table
}