#-------------------------------------------------------------------------------
# CONFIGURATION DE BASE
# Description: Définition des ressources IAM nécessaires pour le cluster EKS
# Date de création: 24/04/2025
# Auteur: DevOps Team
#-------------------------------------------------------------------------------

module "commons" {
  source       = "../commons"
  project_name = var.project_name
  environment  = var.environment
}

locals {
  name = "${var.project_name}-${var.environment}"
}

# Récupération des informations AWS du compte courant
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------
# EKS NODE GROUP ROLE
# Description: Rôle IAM pour les nodes EKS avec les permissions nécessaires 
#              pour rejoindre le cluster et gérer les ressources associées
#-------------------------------------------------------------------------------

resource "aws_iam_role" "node_group" {
  name = "${local.name}-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = module.commons.tags
}

# Policies AWS gérées nécessaires pour EKS nodes
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node_group.name
}

# Policy EBS pour permettre aux nodes de gérer les volumes persistants
resource "aws_iam_role_policy" "node_group_ebs_policy" {
  name = "${local.name}-ebs"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances",
          "ec2:ModifyVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

#-------------------------------------------------------------------------------
# EKS ADMIN ROLE
# Description: Rôle IAM pour les administrateurs du cluster EKS avec
#              permissions complètes sur la gestion du cluster
#-------------------------------------------------------------------------------

resource "aws_iam_role" "eks_admin" {
  name = "${local.name}-eks-admin"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = module.commons.tags
}

# Policy pour le rôle administrateur EKS avec accès complet à l'API EKS
resource "aws_iam_role_policy" "eks_admin" {
  name = "${local.name}-eks-admin"
  role = aws_iam_role.eks_admin.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "iam:GetRole",
          "iam:ListRoles",
          "sts:AssumeRole",
          "kubernetes:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy KMS pour le chiffrement/déchiffrement des secrets dans le cluster
resource "aws_iam_role_policy" "node_group_kms_policy" {
  name = "${local.name}-kms"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      }
    ]
  })
}
