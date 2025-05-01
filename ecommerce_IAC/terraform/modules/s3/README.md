# Module S3 - Gestion du Stockage d'Objets

Ce module Terraform configure les buckets S3 nécessaires pour le stockage des sauvegardes et des logs au sein de la plateforme e-commerce.

## Vue d'ensemble

Amazon S3 (Simple Storage Service) est utilisé comme solution de stockage persistante pour plusieurs aspects critiques de l'infrastructure:

1. **Stockage des sauvegardes** - Conservation des sauvegardes de base de données MongoDB et des ressources Kubernetes via Velero
2. **Centralisation des logs** - Stockage à long terme des journaux d'application collectés par Fluentd

## Architecture de stockage

```
┌───────────────────────────────────────────────────────┐
│                                                       │
│               Plateforme E-commerce                   │
│                                                       │
├─────────────────────────┬─────────────────────────────┤
│                         │                             │
│  ┌─────────────────┐    │    ┌─────────────────────┐  │
│  │                 │    │    │                     │  │
│  │  MongoDB        │────┼───▶│  S3 Backup Bucket   │  │
│  │                 │    │    │                     │  │
│  └─────────────────┘    │    └─────────────────────┘  │
│                         │                             │
│  ┌─────────────────┐    │    ┌─────────────────────┐  │
│  │                 │    │    │                     │  │
│  │  Velero        │────┼───▶│  S3 Backup Bucket   │  │
│  │  (K8s Backup)   │    │    │                     │  │
│  └─────────────────┘    │    └─────────────────────┘  │
│                         │                             │
│  ┌─────────────────┐    │    ┌─────────────────────┐  │
│  │                 │    │    │                     │  │
│  │  Fluentd       │────┼───▶│  S3 Logs Bucket     │  │
│  │  (Log Agent)    │    │    │                     │  │
│  └─────────────────┘    │    └─────────────────────┘  │
│                         │                             │
└─────────────────────────┴─────────────────────────────┘
```

## Buckets configurés

### Bucket de sauvegarde

Ce bucket stocke les données critiques nécessaires à la restauration de l'environnement en cas d'incident:

- **Structure** - Organisé avec des préfixes logiques selon le type de données:
  - `/mongodb/customers/` - Sauvegardes MongoDB du service clients
  - `/mongodb/products/` - Sauvegardes MongoDB du service produits
  - `/mongodb/shopping/` - Sauvegardes MongoDB du service panier
  - `/velero/` - Sauvegardes des ressources Kubernetes

- **Configuration**:
  - Versionnement activé pour protéger contre les suppressions accidentelles
  - Chiffrement AES-256 côté serveur
  - Blocage de tout accès public

### Bucket de logs

Ce bucket centralise tous les journaux d'application pour faciliter l'analyse, le dépannage et les audits:

- **Structure** - Organisé avec une hiérarchie logique:
  - `/audit/` - Logs d'audit pour conformité
  - `/security/` - Logs de sécurité
  - `/access/` - Logs d'accès aux applications
  - `/events/` - Événements système et applicatifs

- **Configuration**:
  - Politique de cycle de vie avec expiration à 30 jours par défaut
  - Chiffrement AES-256 côté serveur
  - Blocage de tout accès public

## Bonnes pratiques implémentées

1. **Sécurité**:
   - Chiffrement des données au repos
   - Blocage d'accès public pour tous les buckets
   - Gestion des autorisations via IAM

2. **Cycle de vie des données**:
   - Politiques d'expiration configurables par type de données
   - Versionnement pour prévenir les suppressions accidentelles

3. **Conformité**:
   - Structure facilitant l'audit et le respect des exigences réglementaires
   - Conservation des logs adaptée aux besoins de conformité

## Variables d'entrée

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `project_name` | Nom du projet pour le tagging des ressources | `string` | `"red-project"` |
| `environment` | Environnement déployé | `string` | `"production"` |
| `retention_days` | Configuration des durées de rétention | `object` | - |

## Sorties

| Nom | Description |
|-----|-------------|
| `backup_bucket` | Informations du bucket backup (Velero) |
| `logs_bucket` | Informations du bucket logs |
| `velero_backup_bucket` | Nom du bucket pour les backups Velero |
| `fluentd_bucket` | Nom du bucket pour Fluentd |

## Intégration avec d'autres modules

Ce module S3 s'intègre avec:

- **Module Velero**: Utilise le bucket de sauvegarde pour stocker les sauvegardes Kubernetes
- **Module EKS**: Les pods Fluentd déployés dans le cluster EKS envoient leurs logs vers le bucket de logs
- **Module IAM**: Définition des autorisations pour l'accès aux buckets

## Considérations de coût

Les buckets S3 génèrent des coûts selon:
- Le volume de stockage utilisé
- Le nombre de requêtes effectuées
- Le transfert de données

Pour optimiser les coûts:
- Des politiques de cycle de vie sont configurées pour supprimer les données obsolètes
- Le versionnement est utilisé de manière sélective

## Évolution future

Ce module pourrait être étendu pour inclure:

- Configuration de réplication entre régions pour la reprise d'activité (DR)
- Intégration avec AWS Macie pour la protection des données sensibles
- Mise en place d'Amazon S3 Analytics pour optimiser les coûts
- Configuration d'Object Lock pour le mode WORM (Write Once Read Many)