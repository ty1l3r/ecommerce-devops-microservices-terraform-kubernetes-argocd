#===============================================================================
# MODULE SECURITY GROUPS - SÉCURISATION DES FLUX RÉSEAU
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module configure les groupes de sécurité pour la plateforme
# e-commerce, permettant:
# - Une isolation réseau entre les différents composants de l'application
# - Des règles de trafic spécifiques pour MongoDB et les microservices
# - Le contrôle précis des communications entrantes et sortantes
# - L'intégration sécurisée avec les nœuds EKS
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
# MONGODB SECURITY GROUP
#===============================================================================
# Groupe de sécurité principal pour les instances MongoDB
# Contrôle les accès aux bases de données MongoDB pour les différents microservices
resource "aws_security_group" "mongodb" {
  name        = "${local.name}-mongodb"
  description = "Security group for MongoDB"
  vpc_id      = var.vpc_id

  tags = module.commons.tags
}

# Règle permettant uniquement aux nœuds EKS d'accéder à MongoDB
# Restreint l'accès à la base de données MongoDB au port standard 27017
resource "aws_security_group_rule" "mongodb_from_nodes" {
  security_group_id        = aws_security_group.mongodb.id
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = var.eks_nodes_security_group_id
  description              = "Allow MongoDB access from EKS nodes"
}

# Règle permettant à MongoDB d'établir des connexions sortantes
# Nécessaire pour les mises à jour, la résolution DNS, etc.
resource "aws_security_group_rule" "mongodb_egress" {
  security_group_id = aws_security_group.mongodb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow MongoDB outbound access"
}

#===============================================================================
# SERVICES SECURITY GROUP
#===============================================================================
# Groupe de sécurité pour les microservices de l'application
# Gère les accès aux API des différents microservices (customers, products, shopping)
resource "aws_security_group" "services" {
  name        = "${local.name}-services"
  description = "Security group for services"
  vpc_id      = var.vpc_id

  tags = module.commons.tags
}

# Règle autorisant les connexions depuis les nœuds EKS vers les microservices
# Permet l'accès aux ports 8001-8003 utilisés par les différents services
resource "aws_security_group_rule" "services_from_nodes" {
  security_group_id        = aws_security_group.services.id
  type                     = "ingress"
  from_port                = 8001
  to_port                  = 8003
  protocol                 = "tcp"
  source_security_group_id = var.eks_nodes_security_group_id
  description              = "Allow services access from EKS nodes"
}

# Règle permettant aux services d'établir des connexions sortantes
# Nécessaire pour les appels API externes, résolution DNS, etc.
resource "aws_security_group_rule" "services_egress" {
  security_group_id = aws_security_group.services.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow services outbound access"
}