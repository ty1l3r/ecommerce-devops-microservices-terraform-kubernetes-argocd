#===============================================================================
# MODULE VPC - INFRASTRUCTURE RÉSEAU PRINCIPALE
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module configure l'infrastructure réseau de base pour la plateforme
# e-commerce, incluant:
# - Un VPC isolé avec adressage personnalisable
# - Une passerelle Internet pour l'accès externe
# - Des tables de routage séparées pour les sous-réseaux publics
#
# Note: Ce module sert de fondation pour l'architecture réseau complète et
# est conçu pour s'intégrer avec les modules de sous-réseaux et de NAT Gateway.
#===============================================================================

#===============================================================================
# COMMONS
#===============================================================================
# Importation du module de ressources communes pour la cohérence du tagging
module "commons" {
  source       = "../commons"
  project_name = var.project_name
  environment  = var.environment
}

#===============================================================================
# LOCALS
#===============================================================================
# Définition d'un préfixe de nommage standardisé pour toutes les ressources
locals {
  name = "${var.project_name}-${var.environment}"
}

#===============================================================================
# VPC
#===============================================================================
# Création du réseau virtuel privé avec support DNS et tagging pour EKS
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Active la résolution des noms d'hôtes DNS dans le VPC
  enable_dns_support   = true  # Active le support DNS pour le VPC
  
  # Ajout de tags standards et spécifiques à EKS pour permettre 
  # la découverte automatique du VPC par le cluster Kubernetes
  tags = merge(module.commons.tags, {
    Name                                        = "${local.name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # Tag requis pour que EKS reconnaisse ce VPC
  })
}

#===============================================================================
# INTERNET GATEWAY
#===============================================================================
# Création de la passerelle Internet pour permettre la communication
# entre le VPC et Internet (nécessaire pour les sous-réseaux publics)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(module.commons.tags, {
    Name = "${local.name}-igw"  # Convention de nommage standardisée
  })
}

#===============================================================================
# ROUTE TABLES
#===============================================================================
# Configuration de la table de routage publique avec une route par défaut
# vers Internet via la passerelle Internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route par défaut dirigeant tout le trafic externe vers Internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # Tags spécifiant l'usage de cette table de routage
  tags = merge(module.commons.tags, {
    Name = "${local.name}-rt-public"
    Tier = "public"  # Facilite l'identification du type de route table
  })
}