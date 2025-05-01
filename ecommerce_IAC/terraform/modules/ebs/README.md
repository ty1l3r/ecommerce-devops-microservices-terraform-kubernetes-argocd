# Module EBS - Gestion du Stockage Persistant

Ce module Terraform configure les volumes EBS nécessaires pour le stockage persistant des bases de données et services de messagerie au sein de la plateforme e-commerce.

## Vue d'ensemble

Amazon EBS (Elastic Block Store) est utilisé comme solution de stockage persistant pour plusieurs composants critiques de l'infrastructure:

1. **Stockage de données MongoDB** - Conservation des données pour chacun des microservices de la plateforme
2. **Stockage RabbitMQ** - Persistance des messages pour la communication inter-services

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
│  │  Customers API  │────┼───▶│  MongoDB Customers  │  │
│  │                 │    │    │  EBS Volume         │  │
│  └─────────────────┘    │    └─────────────────────┘  │
│                         │                             │
│  ┌─────────────────┐    │    ┌─────────────────────┐  │
│  │                 │    │    │                     │  │
│  │  Products API   │────┼───▶│  MongoDB Products   │  │
│  │                 │    │    │  EBS Volume         │  │
│  └─────────────────┘    │    └─────────────────────┘  │
│                         │                             │
│  ┌─────────────────┐    │    ┌─────────────────────┐  │
│  │                 │    │    │                     │  │
│  │  Shopping API   │────┼───▶│  MongoDB Shopping   │  │
│  │                 │    │    │  EBS Volume         │  │
│  └─────────────────┘    │    └─────────────────────┘  │
│                         │                             │
│  ┌─────────────────┐    │    ┌─────────────────────┐  │
│  │                 │    │    │                     │  │
│  │  Microservices  │────┼───▶│  RabbitMQ Volume    │  │
│  │                 │    │    │                     │  │
│  └─────────────────┘    │    └─────────────────────┘  │
│                         │                             │
└─────────────────────────┴─────────────────────────────┘
```

## Volumes configurés

### Volumes MongoDB

Cette configuration provisionne des volumes EBS dédiés pour chaque service de la plateforme:

- **MongoDB Customers** - Stocke les données des clients, leurs profils et préférences
  - **Type**: gp3 (SSD à usage général)
  - **Taille**: 3 GB
  - **Zone**: eu-west-3a

- **MongoDB Products** - Stocke le catalogue de produits, avec descriptions et prix
  - **Type**: gp3 (SSD à usage général)
  - **Taille**: 3 GB
  - **Zone**: eu-west-3a

- **MongoDB Shopping** - Stocke les paniers d'achat et historiques de commandes
  - **Type**: gp3 (SSD à usage général)
  - **Taille**: 3 GB
  - **Zone**: eu-west-3a

- **Configuration**:
  - Volumes dimensionnés pour les besoins actuels avec possibilité d'extension
  - Optimisés pour un bon équilibre entre performance et coût
  - Association à des pods Kubernetes via des PersistentVolumeClaims

### Volume RabbitMQ

Ce volume assure la persistance des files d'attente de messages même en cas de redémarrage:

- **Type**: gp3 (SSD à usage général)
- **Taille**: 3 GB
- **Zone**: eu-west-3a
- **Configuration**:
  - Garantit la non-perte des messages en cas de redémarrage
  - Dimensionné pour gérer les pics de trafic pendant les périodes promotionnelles
  - Essentiel pour l'architecture basée sur les événements

## Bonnes pratiques implémentées

1. **Organisation logique**:
   - Volumes séparés par service pour isoler les données
   - Utilisation de tags cohérents pour faciliter la gestion

2. **Performance optimisée**:
   - Utilisation de volumes gp3 pour un bon rapport IOPS/coût
   - Dimensionnement adapté aux besoins spécifiques de chaque service

3. **Préparation pour évolution**:
   - Code commenté pour faciliter la migration vers une architecture multi-AZ
   - Structure modulaire permettant l'extension vers des configurations HA

## Évolutions futures prévues

Le module inclut déjà du code commenté pour une évolution vers une architecture à haute disponibilité:

1. **Multi-AZ** - Déploiement de réplicas dans différentes zones de disponibilité
2. **Réplication synchrone** - Configuration de MongoDB en mode ReplicaSet
3. **Failover automatique** - Mécanismes de bascule automatique en cas de défaillance
4. **Chiffrement** - Activation du chiffrement pour toutes les données sensibles

## Variables d'entrée

| Nom | Description | Type | Défaut |
|-----|-------------|------|--------|
| `project_name` | Nom du projet pour le tagging des ressources | `string` | - |
| `environment` | Environnement déployé | `string` | - |

## Sorties

| Nom | Description |
|-----|-------------|
| `volumes` | Structure complète contenant les informations de tous les volumes EBS |

## Intégration avec d'autres modules

Ce module EBS s'intègre avec:

- **Module EKS**: Les volumes EBS sont utilisés comme stockage persistant pour les pods Kubernetes
- **Manifestes Kubernetes**: Les PersistentVolumes sont créés en référençant les volumes EBS
- **StorageClasses**: Le module EKS définit des StorageClasses qui utilisent le provisioner EBS CSI
- **Module IAM**: Fournit les permissions nécessaires aux nœuds pour gérer les volumes EBS

## Considérations de coût

Les volumes EBS génèrent des coûts selon:
- Le type de volume (gp3)
- La capacité provisionnée
- Les IOPS et débit supplémentaires éventuels
- La durée d'utilisation

Pour optimiser les coûts:
- Les volumes sont dimensionnés selon les besoins actuels
- Le type gp3 offre un meilleur rapport qualité/prix que gp2
- L'architecture mono-AZ permet de limiter les coûts initiaux