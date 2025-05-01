#===============================================================================
# MODULE S3 - STOCKAGE D'OBJETS POUR BACKUPS ET LOGS
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module configure les buckets S3 pour:
# - Stockage des sauvegardes (MongoDB, Velero)
# - Centralisation des logs d'application et d'infrastructure
# - Conservation des données selon les politiques de rétention configurables
#
# Note: Ce module met en œuvre les bonnes pratiques S3 dont le versionnement,
# le cycle de vie des objets et une organisation standardisée des dossiers.
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
# BUCKET DE BACKUP - Stockage pour les sauvegardes MongoDB et Velero
#===============================================================================
# Définition du bucket principal pour stocker toutes les sauvegardes de la plateforme
# Les données sont organisées en dossiers hiérarchiques par service et type
resource "aws_s3_bucket" "backup" {
  bucket        = "${local.name}-backup-2"
  force_destroy = true  # En production réelle, ceci devrait être false
  tags = merge(module.commons.tags, {
    Purpose = "Backups MongoDB et Velero"
  })
}

# Activation du versionnement pour protéger contre les modifications accidentelles
# et conserver l'historique des versions des fichiers de sauvegarde
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"  # Protection contre la suppression accidentelle des backups
  }
}

# Configuration des règles de cycle de vie pour le bucket backup
# NOTE: Actuellement désactivée car la gestion de la rétention est déléguée à Velero
# qui a son propre mécanisme de purge des sauvegardes expirées
# resource "aws_s3_bucket_lifecycle_configuration" "backup" {
#   bucket = aws_s3_bucket.backup.id

#   depends_on = [
#     aws_s3_bucket.backup,
#     aws_s3_bucket_versioning.backup
#   ]

#   # MongoDB backups - Configuration de rétention par service
#   dynamic "rule" {
#     for_each = ["customers", "products", "shopping"]
#     content {
#       id     = "mongodb_${rule.value}"
#       status = "Enabled"
#       filter {
#         prefix = "mongodb/${rule.value}/"
#       }
#       expiration {
#         days = var.retention_days.backup.mongodb
#       }
#     }
#   }

#   # Velero backups - Configuration de rétention par type de ressource
#   dynamic "rule" {
#     for_each = ["cluster-config", "namespaces", "deployments", "configs"]
#     content {
#       id     = "velero_${rule.value}"
#       status = "Enabled"
#       filter {
#         prefix = "velero/${rule.value}/"
#       }
#       expiration {
#         days = var.retention_days.backup.velero
#       }
#     }
#   }
# }

#===============================================================================
# BUCKET DE LOGS - Stockage pour les journaux d'application
#===============================================================================
# Bucket centralisé pour tous les logs de la plateforme
# Reçoit les logs de Fluentd déployé dans le cluster Kubernetes
resource "aws_s3_bucket" "logs" {
  bucket        = "${local.name}-logs-2"
  force_destroy = true  # En production réelle, à évaluer selon les politiques de conservation
  tags = merge(module.commons.tags, {
    Purpose = "Application Logs"
  })
}

# Configuration du versionnement pour le bucket logs
# Permet de conserver un historique des logs pour analyse forensique si nécessaire
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  # Dépendance explicite pour garantir l'ordre de création
  depends_on = [aws_s3_bucket.logs]

  versioning_configuration {
    status = "Enabled"
  }
}

# Configuration du cycle de vie pour le bucket logs
# Approche simplifiée avec une règle unique pour réduire les problèmes de configuration
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  # Dépendances explicites pour assurer l'ordre de création
  depends_on = [
    aws_s3_bucket.logs,
    aws_s3_bucket_versioning.logs
  ]

  bucket = aws_s3_bucket.logs.id

  # Règle unique pour tous les logs (évite les problèmes de création)
  # Dans une configuration plus avancée, on pourrait définir des règles
  # spécifiques par type de log (audit, sécurité, accès, etc.)
  rule {
    id     = "all_logs_expiration"
    status = "Enabled"

    expiration {
      days = 30  # Période de rétention standard pour les logs
    }
  }

  # Assure une création correcte de la ressource
  lifecycle {
    create_before_destroy = true
  }
}

#===============================================================================
# CONFIGURATION DE SÉCURITÉ POUR LES BUCKETS
#===============================================================================

# Blocage de tout accès public pour les buckets de backup
resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Blocage de tout accès public pour les buckets de logs
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Application du chiffrement côté serveur pour les données sensibles
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}