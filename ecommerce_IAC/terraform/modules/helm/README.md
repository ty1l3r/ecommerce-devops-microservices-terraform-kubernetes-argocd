# Module Helm - Gestion des Applications Kubernetes

Ce module Terraform configure les différentes applications Kubernetes via Helm, nécessaires au fonctionnement de la plateforme e-commerce.

## Vue d'ensemble

Helm est utilisé comme gestionnaire de déploiement pour installer et configurer plusieurs composants essentiels à l'infrastructure:

1. **Ingress Controller** - Point d'entrée pour le trafic externe vers les applications
2. **Cert Manager** - Émission automatique de certificats TLS
3. **Monitoring** - Surveillance de l'infrastructure via Prometheus et Grafana
4. **Sauvegarde** - Sauvegarde et restauration via Velero
5. **Logging** - Centralisation des logs via Fluentd

## Architecture des composants

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                       AWS Load Balancer                         │
│                                                                 │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Nginx Ingress                            │
└───────────┬─────────────────────┬───────────────────────┬───────┘
            │                     │                       │
            ▼                     ▼                       ▼
┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│                   │  │                   │  │                   │
│  Microservices    │  │  Admin UIs        │  │  Grafana          │
│                   │  │  (Monitoring)     │  │                   │
└─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘
          │                      │                      │
          │                      ▼                      │
          │            ┌───────────────────┐            │
          │            │                   │            │
          │────────────│  Cert-Manager     │────────────│
          │            │                   │            │
          │            └───────────────────┘            │
          │                                             │
          ▼                                             ▼
┌───────────────────┐                        ┌───────────────────┐
│                   │                        │                   │
│  Velero           │                        │  Prometheus       │
│  (Backups)        │                        │  (Métriques)      │
└─────────┬─────────┘                        └─────────┬─────────┘
          │                                            │
          ▼                                            ▼
┌───────────────────┐                        ┌───────────────────┐
│                   │                        │                   │
│  S3 Backup        │                        │  Fluentd          │
│  Bucket           │                        │  (Logs)           │
│                   │                        │                   │
└───────────────────┘                        └─────────┬─────────┘
                                                       │
                                                       ▼
                                             ┌───────────────────┐
                                             │                   │
                                             │  S3 Logs          │
                                             │  Bucket           │
                                             │                   │
                                             └───────────────────┘
```

## Composants configurés

### Nginx Ingress Controller

Agit comme point d'entrée pour l'ensemble des services:

- **Chart**: ingress-nginx v4.7.1
- **Configuration**:
  - Exposé via un AWS Network Load Balancer
  - Support de la répartition de charge multi-AZ
  - Ressources optimisées pour une charge modérée
  - Support complet des requêtes ACME pour Let's Encrypt

### Cert Manager

Gère l'émission et le renouvellement automatiques des certificats TLS:

- **Chart**: cert-manager v1.13.3
- **Configuration**:
  - Installation complète des CRDs
  - Ressources minimales pour une empreinte légère
  - Support des webhooks pour la validation automatique
  - Optimisé pour Let's Encrypt avec ACME challenge HTTP01

### Prometheus & Grafana

Fournit une solution complète de monitoring:

- **Chart**: kube-prometheus-stack v45.7.1
- **Configuration**:
  - Retention des métriques de 2 jours
  - Dashboard Grafana accessibles via ingress
  - Sécurisé par authentification
  - Configuration optimisée pour réduire l'utilisation des ressources
  - Collecte des métriques importantes du cluster via node-exporter et kube-state-metrics

### Velero

Assure la sauvegarde et restauration du cluster:

- **Chart**: velero v5.0.2
- **Configuration**:
  - Intégration avec plugin AWS pour S3 et EBS
  - Planification des sauvegardes MongoDB toutes les 5 minutes
  - Conservation des 2 dernières sauvegardes par service
  - Utilisation d'IRSA pour l'authentification AWS sécurisée

### Fluentd

Centralise les logs de l'application:

- **Chart**: fluentd v0.5.0
- **Configuration**: 
  - Expédition des logs vers un bucket S3 dédié
  - Support de l'authentification via IRSA
  - Organisation des logs par application et type
  - Format optimisé pour recherche et analyse

## Bonnes pratiques implémentées

1. **Sécurité**:
   - Chiffrement TLS automatique via Cert Manager
   - Authentification IAM pour l'accès aux ressources AWS
   - RBAC pour les autorisations Kubernetes
   - Isolation des namespaces par fonctionnalité

2. **Haute disponibilité**:
   - Configuration des sondes de vie pour tous les composants
   - Répartition de charge multi-AZ
   - Gestion des timeouts et retries

3. **Performance**:
   - Ressources optimisées pour chaque composant
   - Configuration des limites CPU/mémoire adaptées
   - Durées de rétention ajustées aux besoins

4. **Maintenabilité**:
   - Templates Helm modulaires
   - Versions spécifiques pour chaque chart
   - Documentation complète des paramètres

## Variables d'entrée

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `cluster_name` | Nom du cluster EKS | `string` | - |
| `cluster_endpoint` | Endpoint du cluster EKS | `string` | - |
| `cluster_certificate_authority_data` | Certificate authority data du cluster | `string` | - |
| `nginx_ingress_enabled` | Activer ou désactiver Nginx Ingress | `bool` | `true` |
| `cert_manager_enabled` | Activer ou désactiver Cert Manager | `bool` | `true` |
| `cert_manager_email` | Email pour Let's Encrypt | `string` | - |
| `velero_bucket_name` | Nom du bucket S3 pour Velero | `string` | - |
| `aws_region` | Région AWS | `string` | - |
| `velero_role_arn` | ARN du rôle IAM pour Velero | `string` | - |
| `project_name` | Nom du projet | `string` | - |
| `environment` | Environnement (dev, prod, etc.) | `string` | - |
| `domain_name` | Nom de domaine pour l'ingress | `string` | - |
| `grafana_password` | Mot de passe admin Grafana | `string` | - |
| `logs_bucket_name` | Nom du bucket S3 pour les logs | `string` | - |
| `fluentd_role_arn` | ARN du rôle IAM pour Fluentd | `string` | - |
| `fluentd_enabled` | Activer ou désactiver Fluentd | `bool` | `true` |
| `cluster_oidc_issuer_url` | URL du fournisseur OIDC du cluster EKS | `string` | - |

## Sorties

| Nom | Description |
|-----|-------------|
| `nginx_ingress_hostname` | Hostname du Load Balancer Nginx Ingress |
| `nginx_ingress_namespace` | Namespace de Nginx Ingress |
| `cert_manager_namespace` | Namespace de Cert Manager |
| `prometheus_namespace` | Namespace de Prometheus/Grafana |
| `grafana_url` | URL de Grafana |
| `velero_namespace` | Namespace de Velero |
| `velero_release_name` | Nom de la release Velero |
| `velero_status` | Statut de l'installation Velero |
| `velero_backup_location` | Location des backups Velero |
| `fluentd_namespace` | Namespace de Fluentd |
| `fluentd_release_name` | Nom de la release Fluentd |
| `velero_service_account` | Nom du service account Velero |

## Intégration avec d'autres modules

Ce module Helm s'intègre avec:

- **Module EKS**: Utilise les endpoints et certificats du cluster EKS
- **Module IAM-IRSA**: Utilise les rôles IAM pour les services accounts Kubernetes
- **Module S3**: Utilise les buckets pour les sauvegardes et logs
- **Module EBS**: Sauvegarde les volumes EBS via Velero

## Considérations de coût

Les composants Helm déployés génèrent des coûts selon:
- Le Load Balancer AWS créé par Nginx Ingress
- Le transfert de données entre AZs
- Le stockage S3 pour les logs et sauvegardes
- Les ressources cluster (CPU/RAM) consommées

Pour optimiser les coûts:
- Les ressources des pods sont optimisées au minimum viable
- Les périodes de rétention sont configurées pour limiter le stockage
- La configuration du monitoring est simplifiée
- La compression des logs est activée pour Fluentd

## Extensions futures possibles

Le module pourrait être étendu pour inclure:
- Déploiement d'un mesh service comme Linkerd ou Istio
- Ajout d'Argo Rollouts pour les déploiements canary
- Intégration de Loki pour une meilleure gestion des logs
- Mise en place d'External DNS pour la gestion automatique des enregistrements DNS