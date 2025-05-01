#===============================================================================
# MODULE ARGOCD - DÉPLOIEMENT CONTINU POUR KUBERNETES
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description: Ce module configure ArgoCD pour:
# - Implémenter une approche GitOps pour la gestion des déploiements
# - Synchroniser automatiquement les manifestes depuis le dépôt Git
# - Fournir une interface web pour la gestion et la visualisation des applications
# - Gérer le cycle de vie complet des applications Kubernetes
#
# Note: Ce module intègre ArgoCD avec l'authentification SSH pour accéder
# de façon sécurisée au dépôt Git contenant les manifestes de l'application.
#===============================================================================

#===============================================================================
# HELM RELEASE ARGOCD - DÉPLOIEMENT DE L'OUTIL GITOPS
#===============================================================================
# Installation d'ArgoCD via le chart Helm officiel
# Configuration optimisée pour l'intégration avec notre plateforme e-commerce
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.0"  # Version stable avec support RBAC et HA
  namespace        = "argocd"  # Namespace dédié pour l'isolation
  create_namespace = true      # Création automatique du namespace
  wait             = true      # Attente de la finalisation pour garantir la disponibilité
  timeout          = 900       # Délai étendu pour permettre l'installation complète
  atomic           = true      # Garantit une installation complète ou un rollback

  # Configuration des valeurs personnalisées pour notre environnement
  values = [
    templatefile("${path.module}/template/values.yaml", {
      domain_name           = var.domain_name             # Pour la configuration de l'ingress
      gitlab_repo_url       = var.gitlab_repo_url         # URL du dépôt de manifestes
      app_repository_secret = var.app_repository_secret   # Clé SSH pour l'authentification
    })
  ]
}

#===============================================================================
# SECRET D'AUTHENTIFICATION GIT - ACCÈS SÉCURISÉ AU DÉPÔT
#===============================================================================
# Création d'un secret Kubernetes contenant la clé SSH pour l'authentification
# au dépôt GitLab hébergeant les manifestes applicatifs
resource "kubernetes_secret" "gitlab_ssh" {
  metadata {
    name      = "argocd-repo-secret"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"  # Label spécial reconnu par ArgoCD
    }
  }

  # Configuration du secret avec les informations d'authentification
  type = "Opaque"
  data = {
    type          = "git"                    # Type de source pour ArgoCD
    url           = var.gitlab_repo_url      # URL du dépôt Git à surveiller
    sshPrivateKey = var.app_repository_secret # Clé privée SSH pour l'authentification
  }

  depends_on = [helm_release.argocd]  # S'assure qu'ArgoCD est prêt avant de créer le secret
}

#===============================================================================
# ARGOCD APPLICATIONS - DÉFINITION DES APPLICATIONS À DÉPLOYER
#===============================================================================
# Installation du chart argocd-apps qui définit les applications à gérer
# via l'approche GitOps dans l'environnement cible
resource "helm_release" "argocd-apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = "argocd"
  version    = "2.0.0"  # Version compatible avec notre version d'ArgoCD

  # Configuration des applications à partir d'un template
  values = [
    templatefile("${path.module}/template/application_values.yaml", {
      gitlab_repo_url = var.gitlab_repo_url  # URL du dépôt Git contenant les manifestes
      environment     = var.environment      # Environnement cible (production, staging...)
    })
  ]
  # Dépendances pour s'assurer que l'installation se fait dans le bon ordre
  depends_on = [helm_release.argocd, kubernetes_secret.gitlab_ssh]
}

#===============================================================================
# RÉCUPÉRATION DES INFORMATIONS DE SERVICE - POUR LES OUTPUTS
#===============================================================================
# Récupère les informations du service ArgoCD pour les exposer en sortie
# Utilisé pour construire les URL d'accès et intégrer avec d'autres services
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }
  depends_on = [helm_release.argocd]  # S'assure que le service existe avant de le lire
}
