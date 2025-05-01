#===============================================================================
# MODULE EBS - STOCKAGE PERSISTANT POUR LES BASES DE DONNÉES
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module configure les volumes EBS persistants pour:
# - Stockage des données MongoDB pour les microservices (customers, products, shopping)
# - Stockage persistant pour RabbitMQ (file d'attente de messages)
# - Conservation des données critiques avec configuration optimisée par service
#
# Note: Ce module adopte une approche mono-AZ pour la simplicité initiale,
# mais inclut des commentaires et modèles pour une évolution future vers
# une architecture multi-AZ à haute disponibilité.
#===============================================================================

#===============================================================================
# MODULE COMMONS - Définition des tags standards et nommage
#===============================================================================
module "commons" {
  source       = "../commons"
  project_name = var.project_name
  environment  = var.environment
}

locals {
  name = "${var.project_name}-${var.environment}"
}

#===============================================================================
# EBS VOLUMES - VERSION SIMPLE (MONO-AZ)
#===============================================================================

# MongoDB Customers
# Volume persistant pour stocker les données du service de gestion des clients
# Configuré en gp3 pour un bon équilibre entre performance et coût
resource "aws_ebs_volume" "mongodb_customers_primary" {
  availability_zone = "eu-west-3a"
  size             = 3  # Taille en GB, adaptée aux besoins actuels du service
  type             = "gp3"  # Type SSD à usage général avec bonne performance de base
  encrypted        = false  # À considérer passer à true pour les données sensibles

  tags = merge(module.commons.tags, {
    Name    = "${local.name}-mongodb-customers"
    Service = "mongodb-customers"
  })
}

# MongoDB Products
# Volume persistant pour stocker les données du catalogue de produits
# Le catalogue peut croître significativement avec l'ajout d'images et descriptions
resource "aws_ebs_volume" "mongodb_products_primary" {
  availability_zone = "eu-west-3a"
  size             = 3  # Taille de base, à surveiller avec la croissance du catalogue
  type             = "gp3"  # Offre un bon rapport qualité/prix pour ce type de données
  encrypted        = false  # Pour la production réelle, activer le chiffrement

  tags = merge(module.commons.tags, {
    Name    = "${local.name}-mongodb-products"
    Service = "mongodb-products"
  })
}

# MongoDB Shopping
# Volume persistant pour les données du service de panier d'achats
# Exige une bonne latence pour garantir une expérience utilisateur fluide
resource "aws_ebs_volume" "mongodb_shopping_primary" {
  availability_zone = "eu-west-3a"
  size             = 3  # Dimensionné pour gérer les pics de trafic en période promotionnelle
  type             = "gp3"  # Bon équilibre entre IOPS et coût pour les opérations fréquentes
  encrypted        = false  # Recommandé d'activer en production pour protéger les données client

  tags = merge(module.commons.tags, {
    Name    = "${local.name}-mongodb-shopping"
    Service = "mongodb-shopping"
  })
}

# RabbitMQ
# Volume persistant pour les files d'attente de messages
# Critique pour assurer la fiabilité et la non-perte des événements inter-services
resource "aws_ebs_volume" "rabbitmq_primary" {
  availability_zone = "eu-west-3a"
  size             = 3  # Configurer selon les estimations de trafic et de rétention des messages
  type             = "gp3"  # Performance constante requise pour le traitement des messages
  encrypted        = false  # Considérer l'activation du chiffrement selon la sensibilité du contenu

  tags = merge(module.commons.tags, {
    Name    = "${local.name}-rabbitmq"
    Service = "rabbitmq"
  })
}

#===============================================================================
# POUR FUTURE IMPLEMENTATION HA (MULTI-AZ)
#===============================================================================
# Notes d'architecture:
# Pour évoluer vers une architecture à haute disponibilité, nous devrons:
# 1. Créer des réplicas des volumes dans des AZ différentes
# 2. Configurer la réplication au niveau applicatif (ex: MongoDB ReplicaSet)
# 3. Mettre en place un mécanisme de failover automatique
# 4. Adapter les ressources Kubernetes pour exploiter cette redondance

# MongoDB Customers HA
# resource "aws_ebs_volume" "mongodb_customers_replica" {
#   availability_zone = "eu-west-3b"
#   size             = 2
#   type             = "gp3"
#   encrypted        = true
#   tags = merge(module.commons.tags, {
#     Name    = "${local.name}-mongodb-customers-replica"
#     Service = "mongodb-customers"
#   })
# }

# MongoDB Products HA
# resource "aws_ebs_volume" "mongodb_products_replica" {...}

# MongoDB Shopping HA
# resource "aws_ebs_volume" "mongodb_shopping_replica" {...}

# RabbitMQ HA
# resource "aws_ebs_volume" "rabbitmq_replica" {...}