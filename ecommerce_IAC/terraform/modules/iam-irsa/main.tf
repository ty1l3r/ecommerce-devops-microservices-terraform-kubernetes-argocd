#-------------------------------------------------------------------------------
# MODULE IAM IRSA: IDENTITY-BASED ACCESS CONTROL FOR KUBERNETES
#-------------------------------------------------------------------------------
# Ce module implémente IAM Roles for Service Accounts (IRSA), permettant aux
# pods Kubernetes d'accéder de façon sécurisée aux services AWS via des rôles IAM
# dédiés. Cette approche élimine le besoin de stocker des credentials AWS et
# applique le principe de moindre privilège.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# CONFIGURATION DE BASE
#-------------------------------------------------------------------------------
module "commons" {
  source       = "../commons"
  project_name = var.project_name
  environment  = var.environment
}

locals {
  name = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

#-------------------------------------------------------------------------------
# FLUENTD IRSA
#-------------------------------------------------------------------------------
# Rôle IAM permettant au service Fluentd de collecter et stocker les logs
# applicatifs dans un bucket S3 dédié.
#-------------------------------------------------------------------------------
resource "aws_iam_role" "fluentd" {
  name = "${local.name}-fluentd"
  description = "Rôle IAM pour Fluentd permettant d'envoyer les logs vers S3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.eks_oidc_provider}:sub" : "system:serviceaccount:logging:fluentd"
        }
      }
    }]
  })

  tags = merge(
    module.commons.tags,
    {
      Name = "${local.name}-fluentd-role"
      Service = "Logging"
    }
  )
}

resource "aws_iam_role_policy" "fluentd_s3" {
  name = "${local.name}-fluentd-s3"
  role = aws_iam_role.fluentd.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",     # Pour écrire les fichiers de logs
        "s3:GetObject",     # Pour récupérer les fichiers si nécessaire
        "s3:ListBucket",    # Pour voir le contenu du bucket
        "s3:PutObjectTagging", # Pour taguer les objets
        "s3:DeleteObject"   # Pour supprimer les logs obsolètes
      ]
      Resource = [
        "${var.logs_bucket_arn}/*",  # Accès aux objets dans le bucket
        var.logs_bucket_arn          # Accès au bucket lui-même
      ]
    }]
  })
}

#-------------------------------------------------------------------------------
# MONGODB BACKUP IRSA
#-------------------------------------------------------------------------------
# Rôle IAM permettant au job de sauvegarde MongoDB de stocker les dumps
# dans un bucket S3 sécurisé.
#-------------------------------------------------------------------------------
resource "aws_iam_role" "mongodb_backup" {
  name = "${local.name}-mongodb-backup"
  description = "Rôle IAM pour les sauvegardes MongoDB vers S3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.eks_oidc_provider}:sub" : "system:serviceaccount:mongodb:mongodb-backup"
        }
      }
    }]
  })

  tags = merge(
    module.commons.tags,
    {
      Name = "${local.name}-mongodb-backup-role"
      Service = "Database"
    }
  )
}

resource "aws_iam_role_policy" "mongodb_s3" {
  name = "${local.name}-mongodb-s3"
  role = aws_iam_role.mongodb_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",  # Pour écrire les sauvegardes
        "s3:GetObject",  # Pour récupérer les sauvegardes lors des restaurations
        "s3:ListBucket", # Pour lister les backups disponibles
        "s3:DeleteObject" # Pour gérer la rétention des backups
      ]
      Resource = [
        "${var.backup_bucket_arn}/mongodb/*",  # Accès limité au préfixe mongodb/
        var.backup_bucket_arn                  # Accès au bucket pour le listing
      ]
    }]
  })
}

#-------------------------------------------------------------------------------
# VELERO IRSA
#-------------------------------------------------------------------------------
# Rôle IAM pour Velero, l'outil de sauvegarde et restauration Kubernetes.
# Ce rôle permet à Velero de créer des snapshots de volumes EBS et de stocker
# ses sauvegardes dans S3.
#-------------------------------------------------------------------------------
resource "aws_iam_role" "velero" {
  name = "${local.name}-velero"
  description = "Rôle IAM pour Velero (sauvegarde/restauration Kubernetes)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.eks_oidc_provider}:aud" : "sts.amazonaws.com",
          "${var.eks_oidc_provider}:sub" : "system:serviceaccount:${var.velero_namespace}:${var.velero_service_account}"
        }
      }
    }]
  })

  tags = merge(
    module.commons.tags,
    {
      Name = "${local.name}-velero-role"
      Service = "Backup"
    }
  )
}

# Politique complète pour Velero gérant à la fois les sauvegardes S3 et les snapshots EBS
resource "aws_iam_policy" "velero_policy" {
  name        = "${local.name}-velero-policy"
  description = "Politique IAM permettant à Velero de sauvegarder/restaurer des clusters Kubernetes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions EC2 pour gérer les snapshots de volumes
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      },
      # Permissions S3 pour stocker les backups Kubernetes
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:PutObjectTagging",
          "s3:GetObjectTagging"
        ]
        Resource = [
          "${var.backup_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.backup_bucket_arn
        ]
      }
    ]
  })

  tags = merge(
    module.commons.tags,
    {
      Name = "${local.name}-velero-policy"
      Service = "Backup"
    }
  )
}

# Attachement de la policy au rôle Velero
resource "aws_iam_role_policy_attachment" "velero_policy_attachment" {
  role       = aws_iam_role.velero.name
  policy_arn = aws_iam_policy.velero_policy.arn
}



