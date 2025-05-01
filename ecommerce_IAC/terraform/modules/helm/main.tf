#===============================================================================
# MODULE HELM - DÉPLOIEMENT DES APPLICATIONS KUBERNETES
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module configure les différents composants d'infrastructure
# de la plateforme e-commerce via Helm, incluant:
# - Nginx Ingress Controller pour la gestion du trafic externe
# - Cert-Manager pour la gestion automatique des certificats TLS
# - Prometheus et Grafana pour le monitoring
# - Velero pour les sauvegardes et restaurations
# - Fluentd pour la centralisation des logs vers S3
#
# Note: Les différents charts sont déployés avec des configurations optimisées
# et des intégrations avec AWS via IRSA pour une sécurité renforcée.
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
# NGINX INGRESS CONTROLLER
#===============================================================================
# Point d'entrée pour tout le trafic externe vers les applications
# Exposé via un AWS Load Balancer avec support TLS
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.7.1"  # Version stable avec support AWS NLB
  timeout          = 900      # Timeout élevé pour assurer le déploiement complet du load balancer
  wait             = true     # Attente de la finalisation pour garantir la disponibilité
  values = [
    file("${path.module}/values/nginx-ingress-values.yaml")
  ]
}

#===============================================================================
# CERT-MANAGER
#===============================================================================
# Service de gestion automatique des certificats TLS via Let's Encrypt
# Intégré avec Nginx Ingress pour valider les certificats via challenge HTTP01
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  version          = "v1.13.3"  # Version stable avec support complet des CRDs
  create_namespace = true

  values = [
    templatefile("${path.module}/values/cert-manager.yaml", {})
  ]

  # Installation des CRDs nécessaires pour la gestion des certificats et émetteurs
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Optimisation des performances du webhook pour éviter les timeouts
  set {
    name  = "webhook.timeoutSeconds"
    value = "10"  # Valeur optimisée pour réduire les délais de validation
  }

  # Configuration avancée pour la gestion des certificats et références propriétaires
  set {
    name  = "extraArgs[0]"
    value = "--enable-certificate-owner-ref=true"  # Facilite le nettoyage automatique
  }

  # Optimisation des requêtes DNS pour la validation des challenges
  set {
    name  = "extraArgs[1]"
    value = "--dns01-recursive-nameservers-only"
  }

  # Configuration des webhooks pour éviter les blocages lors des mises à jour
  set {
    name  = "webhook.mutating.failurePolicy"
    value = "Ignore"  # Mode plus permissif pour faciliter les opérations de maintenance
  }

  set {
    name  = "webhook.validating.failurePolicy"
    value = "Ignore"  # Mode plus permissif pour faciliter les opérations de maintenance
  }

  # Paramètres de gestion du cycle de vie pour une installation robuste
  cleanup_on_fail = true
  force_update    = true
  recreate_pods   = false  # Évite de recréer inutilement les pods pendant la destruction

  # Gestion optimisée des timeouts pour l'installation
  timeout = 300  # Valeur ajustée pour éviter les attentes excessives
  wait    = true
  atomic  = false  # Désactivé pour permettre des opérations graduelles

  depends_on = [
    helm_release.nginx_ingress
  ]

  # Nettoyage manuel des CRDs lors de la destruction pour éviter les blocages
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete crd -l app.kubernetes.io/instance=cert-manager --force --grace-period=0 || true
      kubectl delete validatingwebhookconfiguration -l app.kubernetes.io/instance=cert-manager --force --grace-period=0 || true
      kubectl delete mutatingwebhookconfiguration -l app.kubernetes.io/instance=cert-manager --force --grace-period=0 || true
      kubectl delete namespace cert-manager --force --grace-period=0 || true
    EOT
  }
}

# Délai d'attente pour s'assurer que les CRDs sont correctement enregistrées
# avant de déployer les autres composants qui en dépendent
resource "time_sleep" "wait_for_cert_manager_ready" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "90s"  # Durée optimisée par tests empiriques
}

#===============================================================================
# PROMETHEUS & GRAFANA
#===============================================================================
# Stack de monitoring complet incluant:
# - Prometheus pour la collecte et le stockage des métriques
# - Grafana pour la visualisation et les tableaux de bord
# - AlertManager pour la gestion des alertes
# - Node-exporter et kube-state-metrics pour les métriques système
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"  # Chart combiné pour une solution complète
  namespace        = "monitoring"
  version          = "45.7.1"
  create_namespace = true

  values = [
    templatefile("${path.module}/values/prometheus-values.yaml", {
      domain_name      = var.domain_name
      grafana_password = var.grafana_password
      environment      = var.environment
    })
  ]
  timeout = 600  # Délai étendu pour permettre le déploiement complet de tous les composants
  wait    = true
  depends_on = [
    helm_release.nginx_ingress,
    time_sleep.wait_for_cert_manager_ready
  ]
}

#===============================================================================
# VELERO - SAUVEGARDE ET RESTAURATION
#===============================================================================
# Solution de sauvegarde et restauration pour Kubernetes
# Intégrée avec AWS S3 pour le stockage des sauvegardes
# et EBS pour les snapshots de volumes persistants

# Création d'un namespace dédié avec les labels appropriés
resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
    labels = {
      name = "velero"
    }
  }
}

# Déploiement de Velero avec configuration AWS pour S3 et EBS
resource "helm_release" "velero" {
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  version          = "5.0.2"
  namespace        = kubernetes_namespace.velero.metadata[0].name
  create_namespace = false

  # Paramètres avancés pour garantir une installation complète
  timeout       = 1200  # Timeout étendu pour la création de tous les CRDs et controllers
  wait          = true
  wait_for_jobs = true  # Attente des jobs d'initialisation

  values = [
    templatefile("${path.module}/values/velero-values.yaml", {
      bucket_name     = var.velero_bucket_name
      aws_region      = var.aws_region
      velero_role_arn = var.velero_role_arn
    })
  ]
  # Force la recréation si les configurations changent
  recreate_pods = true
  depends_on = [
    kubernetes_namespace.velero,
    helm_release.nginx_ingress
  ]
}

#===============================================================================
# FLUENTD - CENTRALISATION DES LOGS
#===============================================================================
# Collecte et expédition des logs vers S3 pour archivage et analyse
# Configuration sécurisée via IRSA pour l'authentification AWS

# Namespace dédié pour l'infrastructure de logging
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      name = "logging"
    }
  }
}

# Déploiement de Fluentd avec intégration S3
resource "helm_release" "fluentd" {
  name             = "fluentd"
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluentd"
  namespace        = kubernetes_namespace.logging.metadata[0].name
  version          = "0.5.0"  # Version récente avec corrections de sécurité
  create_namespace = false
  timeout          = 600
  wait             = false  # Installation en arrière-plan pour éviter les blocages
  recreate_pods    = true   # Force la recréation pour appliquer les nouvelles configurations
  force_update     = true   # S'assure que les modifications sont bien appliquées

  # Configuration RBAC nécessaire pour accéder aux logs du cluster
  set {
    name  = "rbac.create"
    value = "true"
  }
  # Sécurisation des conteneurs Fluentd
  set {
    name  = "podSecurityContext.enabled"
    value = "true"
  }
  values = [
    templatefile("${path.module}/values/fluentd-values.yaml", {
      logs_bucket      = "${var.project_name}-${var.environment}-logs-2"
      aws_region       = var.aws_region
      fluentd_role_arn = var.fluentd_role_arn
    })
  ]

  depends_on = [
    kubernetes_namespace.logging
  ]
}


