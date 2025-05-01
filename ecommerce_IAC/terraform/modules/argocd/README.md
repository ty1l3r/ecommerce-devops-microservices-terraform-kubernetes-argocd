# Module ArgoCD - Déploiement Continu GitOps

Ce module Terraform configure ArgoCD, l'outil GitOps qui permet d'automatiser le déploiement, la configuration et la gestion des applications Kubernetes pour notre plateforme e-commerce.

## Vue d'ensemble

ArgoCD implémente l'approche GitOps où Git devient la source unique de vérité pour les déploiements, offrant:

1. **Déploiement continu** - Synchronisation automatique depuis le dépôt Git
2. **Gestion déclarative** - État souhaité défini dans Git avec réconciliation automatique
3. **Interface visuelle** - Visualisation du statut des déploiements et de la santé des applications
4. **Sécurité intégrée** - Authentification Git via SSH et intégration RBAC

## Architecture de déploiement

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    GitLab Repository                            │
│                (Production Manifests)                           │
│                                                                 │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                │ SSH Authentication
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                        ArgoCD Server                            │
│                                                                 │
├─────────────────────┬───────────────────────┬──────────────────┤
│                     │                       │                   │
│  API Server         │  Repository Server    │  Application      │
│  (REST API)         │  (Git Operations)     │  Controller       │
│                     │                       │                   │
└─────────┬───────────┴───────────┬───────────┴────────┬──────────┘
          │                       │                    │
          │                       │                    │
          ▼                       │                    │
┌──────────────────┐              │                    │
│                  │              │                    │
│  Web UI          │              │                    │
│  (Management)     │              │                    │
│                  │              │                    │
└─────────┬────────┘              │                    │
          │                       │                    │
          │    ┌──────────────────┘                    │
          │    │                                       │
          ▼    ▼                                       │
┌─────────────────────┐                                │
│                     │                                │
│  Ingress Controller │                                │
│  (Public Access)    │                                │
│                     │                                │
└─────────────────────┘                                │
                                                       │
                                                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                   Kubernetes Cluster                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Composants configurés

### ArgoCD Core

Le cœur d'ArgoCD déployé avec une configuration optimisée pour notre plateforme e-commerce:

- **Chart**: argo-cd v5.51.0
- **Configuration**:
  - Interface Web exposée via Ingress
  - Support CORS activé pour l'API
  - Mode sécurisé via authentification
  - Optimisations de performance pour la gestion de nombreuses applications

### Authentification Git

Configuration sécurisée pour l'accès au dépôt Git:

- **Type**: SSH avec clé privée
- **Secret Kubernetes**: `argocd-repo-secret`
- **Intégration**: Labels spéciaux pour auto-détection par ArgoCD
- **Sécurité**: Stockage sécurisé des informations d'identification

### Applications GitOps

Définition du modèle d'application qui sera géré par ArgoCD:

- **Chart**: argocd-apps v2.0.0
- **Configuration**:
  - Synchronisation automatique des applications
  - Auto-healing en cas de dérive
  - Processus de préparation/nettoyage
  - Gestion avancée des ressources Kubernetes

## Bonnes pratiques implémentées

1. **Sécurité**:
   - Authentification SSH pour l'accès au dépôt Git
   - Namespaces isolés pour une meilleure séparation
   - Exposition sécurisée via Ingress avec options de protection

2. **Maintenabilité**:
   - Architecture modulaire du déploiement
   - Versions spécifiques des charts pour stabilité
   - Templates externalisés pour faciliter les modifications

3. **GitOps**:
   - État défini déclarativement dans Git
   - Réconciliation automatique avec l'état souhaité
   - Audit complet des changements via l'historique Git

4. **Haute disponibilité**:
   - Architecture multi-composants permettant la résilience
   - Gestion des échecs de synchronisation
   - Stratégies de récupération intégrées

## Variables d'entrée

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `gitlab_repo_url` | URL du repository contenant les manifestes | `string` | `git@gitlab.com:wonder-team-devops/prod-manifest.git` |
| `app_repository_secret` | Clé SSH pour l'authentification Git (sensible) | `string` | - |
| `domain_name` | Nom de domaine pour l'ingress ArgoCD | `string` | - |
| `environment` | Environnement cible (production, staging...) | `string` | `production` |
| `helm_dependencies` | Liste des dépendances Helm à attendre | `list(any)` | `[]` |

## Sorties

| Nom | Description |
|-----|-------------|
| `argocd_namespace` | Namespace où ArgoCD est déployé |
| `argocd_server_url` | URL complète pour accéder à l'interface ArgoCD |
| `argocd_server_service_name` | Nom du service ArgoCD Server |
| `argocd_repository_credentials` | Statut des credentials du repository Git |
| `argocd_applications` | Détails des applications configurées |
| `argocd_ingress_host` | Hostname de l'ingress ArgoCD |

## Intégration avec d'autres modules

Ce module ArgoCD s'intègre avec:

- **Module EKS**: Utilise le cluster Kubernetes déployé
- **Module Helm**: Dépendance attendue pour Nginx Ingress
- **Module IAM-IRSA**: Pour d'éventuelles intégrations avec des services AWS
- **Dépôt Git externe**: Source de vérité pour les applications déployées

## Considérations opérationnelles

### Accès à l'interface Web

L'interface ArgoCD est accessible via:
- URL: http://argocd.${domain_name}
- Authentification initiale: Générée par ArgoCD et stockée dans un secret Kubernetes

### Workflow de déploiement

1. Les modifications sont poussées vers le dépôt de manifestes Git
2. ArgoCD détecte les changements et compare avec l'état actuel
3. ArgoCD applique automatiquement les changements selon la configuration
4. Le statut de synchronisation est visible dans l'interface

### Récupération en cas d'erreur

En cas de problème avec ArgoCD:
- Le module peut être réappliqué pour restaurer la configuration
- Les applications peuvent être resynchronisées manuellement via l'interface
- L'état Git reste la source de vérité pour reconstruire si nécessaire

## Évolutions futures possibles

Le module pourrait être étendu pour inclure:
- Support du SSO pour l'authentification utilisateur
- Intégration avec Notifications (Slack, Teams, etc.)
- Configuration avancée des stratégies de déploiement (Blue/Green, Canary)
- Extension vers un modèle multi-cluster