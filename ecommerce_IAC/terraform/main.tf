#===============================================================================
# INFRASTRUCTURE TERRAFORM - PLATEFORME E-COMMERCE GITOPS
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Ce fichier définit l'infrastructure complète pour la plateforme e-commerce,
# en suivant une approche modulaire. Les modules sont exécutés dans un ordre
# spécifique pour respecter les dépendances entre ressources.
#===============================================================================

#===============================================================================
# CONFIGURATION COMMUNE
#===============================================================================
# Module de base pour les tags et conventions de nommage communs
module "commons" {
  source       = "./modules/commons"
  project_name = var.project_name
  environment  = var.environment
}

# Définition du nom standardisé du cluster pour une utilisation cohérente
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
}

#===============================================================================
# INFRASTRUCTURE RÉSEAU
#===============================================================================
# 1. VPC - Réseau virtuel isolé pour l'ensemble de l'infrastructure
module "vpc" {
  source             = "./modules/vpc"
  project_name       = var.project_name
  environment        = var.environment
  availability_zones = var.availability_zones
  cluster_name       = local.cluster_name
}

# 2. Sous-réseaux publics - Pour les ressources accessibles depuis internet 
# (Load Balancers, Bastion hosts, etc.)
module "public_subnets" {
  source                = "./modules/subnets"
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  availability_zones    = var.availability_zones
  subnets_cidr          = var.public_subnets_cidr
  public_subnets_cidr   = var.public_subnets_cidr
  public_route_table_id = module.vpc.public_route_table_id
  cluster_name          = local.cluster_name
  private               = false
  depends_on            = [module.vpc]
}

# 3. NAT Gateways - Permettent l'accès internet aux ressources dans les sous-réseaux privés
# tout en protégeant ces ressources de l'accès externe direct
module "nat" {
  source             = "./modules/nat"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  availability_zones = var.availability_zones
  public_subnet_ids  = module.public_subnets.public_subnet_ids
  depends_on         = [module.public_subnets]
}

# 4. Sous-réseaux privés - Isolation complète pour les composants sensibles
# (EKS, bases de données, etc.)
module "private_subnets" {
  source               = "./modules/subnets"
  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  availability_zones   = var.availability_zones
  subnets_cidr         = var.private_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  nat_gateway_ids      = module.nat.nat_gateway_ids
  cluster_name         = local.cluster_name
  private              = true
  depends_on           = [module.vpc, module.nat]
}

#===============================================================================
# STOCKAGE ET PERSISTANCE
#===============================================================================
# Buckets S3 pour backups, logs et état Terraform
# Déplacé avant IAM pour pouvoir référencer les ARNs dans les politiques IAM
module "s3" {
  source         = "./modules/s3"
  project_name   = var.project_name
  environment    = var.environment
  retention_days = var.retention_days
}

# Volumes EBS persistants pour les bases de données (MongoDB, RabbitMQ)
module "ebs" {
  source       = "./modules/ebs"
  project_name = var.project_name
  environment  = var.environment
  depends_on   = [module.vpc]
}

#===============================================================================
# GESTION DES IDENTITÉS ET DES ACCÈS
#===============================================================================
# Configuration IAM de base - Rôles pour EKS, noeuds workers et autres services AWS
module "iam_base" {
  source             = "./modules/iam"
  project_name       = var.project_name
  environment        = var.environment
  tfstate_bucket     = var.tf_state_bucket
  backup_bucket_name = module.s3.backup_bucket.name
  depends_on         = [module.s3]
}

#===============================================================================
# KUBERNETES (EKS)
#===============================================================================
# Cluster EKS - Orchestration des conteneurs pour l'application e-commerce
# Déployé dans les sous-réseaux privés pour une sécurité maximale
module "eks" {
  source       = "./modules/eks"
  project_name = var.project_name
  environment  = var.environment
  cluster_name = local.cluster_name
  vpc_config = {
      vpc_id     = module.vpc.vpc_id
      subnet_ids = module.private_subnets.private_subnet_ids
    }
  eks_admins_iam_role_arn = module.iam_base.eks_admin_role_arn
  mongodb_storage_class   = var.mongodb_storage_class
  node_role_arn           = module.iam_base.node_group_role_arn
  depends_on = [
    module.vpc,
    module.private_subnets,
    module.public_subnets,
    module.iam_base,
    module.s3
  ]
}

#===============================================================================
# IAM POUR KUBERNETES (IRSA)
#===============================================================================
# Configuration IAM pour Service Accounts - Intégration sécurisée entre services Kubernetes
# et services AWS comme S3, sans avoir à gérer des credentials AWS directement dans Kubernetes
module "iam_irsa" {
  source                = "./modules/iam-irsa"
  project_name          = var.project_name
  environment           = var.environment
  eks_oidc_provider     = module.eks.oidc_provider
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  backup_bucket_arn     = module.s3.backup_bucket.arn
  logs_bucket_arn       = module.s3.logs_bucket.arn
  tf_state_bucket       = var.tf_state_bucket
  depends_on            = [module.eks]
}

#===============================================================================
# GITOPS ET DÉPLOIEMENT CONTINU
#===============================================================================
# ArgoCD - Outil GitOps pour le déploiement continu basé sur l'état déclaré dans Git
module "argocd" {
  source = "./modules/argocd"

  # Configuration de l'intégration avec le dépôt GitLab contenant les manifestes Kubernetes
  gitlab_repo_url       = "git@gitlab.com:repo-prod-manifest.git"
  app_repository_secret = var.app_repository_secret
  domain_name           = var.domain_name
  environment           = var.environment

  # Assure que l'ingress controller est disponible avant d'installer ArgoCD
  helm_dependencies = [
    module.helm.nginx_ingress_hostname
  ]

  depends_on = [
    module.helm.nginx_ingress_hostname,
    module.eks
  ]
}

#===============================================================================
# COMPOSANTS ADDITIONNELS KUBERNETES
#===============================================================================
# Installation des composants additionnels essentiels via Helm:
# - Nginx Ingress Controller: Gestion du trafic entrant 
# - Cert-Manager: Automatisation des certificats TLS
# - Prometheus & Grafana: Monitoring et visualisation
# - Velero: Sauvegarde et restauration du cluster
# - Fluentd: Collecte et exportation des logs vers S3
module "helm" {
  source = "./modules/helm"

  project_name                       = var.project_name
  environment                        = var.environment
  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  cluster_oidc_issuer_url            = module.eks.cluster_oidc_issuer_url
  domain_name                        = var.domain_name
  grafana_password                   = var.grafana_password
  cert_manager_email                 = var.cert_manager_email
  aws_region                         = var.aws_region
  velero_bucket_name                 = module.s3.backup_bucket.name
  logs_bucket_name                   = module.s3.logs_bucket.name
  velero_role_arn                    = module.iam_irsa.velero_role_arn
  fluentd_role_arn                   = module.iam_irsa.fluentd_role_arn

  depends_on = [
    module.eks,
    module.iam_irsa,
    module.s3
  ]
}


