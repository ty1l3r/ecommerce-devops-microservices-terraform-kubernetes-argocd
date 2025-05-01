#===============================================================================
# MODULE EKS - ORCHESTRATION DES CONTENEURS KUBERNETES
# Auteur: Tyler
# Dernière mise à jour: Avril 2025
#
# Description: Ce module déploie et configure un cluster Amazon EKS pour:
# - Fournir une plateforme d'orchestration robuste pour les microservices
# - Gérer les ressources compute avec scaling automatique
# - Configurer le stockage persistant via EBS CSI Driver
# - Intégrer l'authentification IAM avec OIDC pour les service accounts
#
# Note: Ce module utilise la configuration standard d'EKS avec des optimisations
# pour les performances et la sécurité de la plateforme e-commerce.
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
# CLUSTER EKS - DÉPLOIEMENT DU PLAN DE CONTRÔLE ET DES NŒUDS
#===============================================================================
# Récupération de la clé KMS par défaut pour le chiffrement EBS
data "aws_kms_key" "ebs_default" {
  key_id = "alias/aws/ebs"
}

# Déploiement du cluster EKS via le module communautaire officiel
# Configuration optimisée pour équilibrer performance, coût et sécurité
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"  # Version récente avec toutes les fonctionnalités nécessaires

  # Configuration de base du cluster
  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version  # Défini par variable pour faciliter les mises à jour
  enable_cluster_creator_admin_permissions = true  # Simplifie la gestion initiale du cluster

  # Configuration réseau du cluster - utilise le VPC et sous-réseaux fournis
  vpc_id     = var.vpc_config.vpc_id
  subnet_ids = var.vpc_config.subnet_ids  # Sous-réseaux privés pour l'isolation réseau

  # Configuration des points d'accès - permettant l'accès depuis le réseau interne et externe
  cluster_endpoint_private_access      = true  # Accès depuis les ressources du VPC
  cluster_endpoint_public_access       = true  # Accès depuis l'extérieur pour faciliter la gestion
  cluster_endpoint_public_access_cidrs = var.cluster_public_access_cidrs  # Contrôle d'accès par CIDR

  # Optimisation des coûts - désactivation de certaines fonctionnalités premium
  create_kms_key              = false  # Utilisation de la clé KMS AWS par défaut
  create_cloudwatch_log_group = false  # Gestion des logs via Fluentd vers S3 plutôt que CloudWatch
  cluster_encryption_config   = {}     # Désactivation du chiffrement des secrets Kubernetes

  # Configuration des addons essentiels EKS - toujours à la version la plus récente
  cluster_addons = {
    coredns = {
      most_recent = true  # Résolution DNS intra-cluster essentielle
    }
    kube-proxy = {
      most_recent = true  # Networking intra-pod
    }
    vpc-cni = {
      most_recent = true  # Networking AWS optimisé
    }
    aws-ebs-csi-driver = {
      most_recent = true  # Support des volumes persistants EBS
    }
  }

  # Configuration du groupe de nœuds managés - workers Kubernetes
  eks_managed_node_groups = {
    main = {
      name = "${var.project_name}-${var.environment}-ng"  # Nom standardisé pour les nœuds
      use_name_prefix = false  # Utilisation du nom exact pour faciliter l'identification
      create_iam_role = false  # Utilisation d'un rôle IAM pré-configuré depuis le module IAM
      iam_role_arn    = var.node_role_arn  # Rôle avec les permissions nécessaires

      # Configuration du scaling automatique
      min_size       = var.nodes_min_size
      max_size       = var.nodes_max_size
      desired_size   = var.nodes_desired_size
      instance_types = var.instance_types  # Types d'instance optimisés pour le rapport coût/performance

      # Configuration des volumes racine des nœuds
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = var.node_volume_size  # Taille suffisante pour les composants système
            volume_type = "gp3"                 # Meilleur rapport performance/coût
            encrypted   = false                 # À considérer activer en environnement hautement sécurisé
          }
        }
      }
    }
  }

  # Tags pour faciliter l'identification et l'intégration avec les autres services AWS
  tags = merge(module.commons.tags, {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # Tag requis pour l'intégration avec ALB/NLB
  })

  # Activation d'IAM Roles for Service Accounts - sécurité Zero-Trust
  enable_irsa = true  # Permet aux pods d'accéder aux services AWS de façon sécurisée
}

#===============================================================================
# STORAGE CLASSES - CONFIGURATION DES VOLUMES PERSISTANTS
#===============================================================================
# StorageClass gp3 par défaut - meilleur rapport performance/coût pour les volumes
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"  # Défini comme StorageClass par défaut
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"  # Utilise le driver EBS CSI déployé comme addon
  volume_binding_mode    = "WaitForFirstConsumer"  # Optimisation: crée le volume dans l'AZ où le pod est déployé
  allow_volume_expansion = true  # Permet le redimensionnement des volumes sans recréation
  parameters = {
    type      = "gp3"  # Type de volume EBS offrant un bon équilibre performance/coût
    encrypted = "false"  # Chiffrement désactivé par défaut, à activer selon les besoins
  }
  depends_on = [module.eks]  # S'assure que le cluster et l'addon EBS CSI sont prêts
}

# Désactivation de gp2 comme StorageClass par défaut
# Nécessaire car AWS définit gp2 par défaut, mais gp3 offre un meilleur rapport performance/coût
resource "kubernetes_annotations" "remove_gp2_default" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"  # Retrait du statut par défaut
  }
  force = true  # Force la mise à jour même en cas de conflit
  depends_on = [
    module.eks,
    kubernetes_storage_class.gp3  # S'assure que gp3 est déjà défini comme défaut
  ]
  # Création de la StorageClass gp2 si elle n'existe pas
  # Nécessaire car certains pods/charts peuvent spécifiquement demander gp2
  provisioner "local-exec" {
    command    = "kubectl get storageclass gp2 || kubectl create storageclass gp2 --provisioner=kubernetes.io/aws-ebs"
    on_failure = continue  # Continue même si la commande échoue
  }
}

# Export de l'ARN du provider OIDC pour l'utilisation dans d'autres modules (IRSA)
locals {
  oidc_provider_arn = module.eks.oidc_provider_arn
}
