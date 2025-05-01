# Module NAT Gateway - Connectivité Internet Sortante Sécurisée

Ce module Terraform configure les NAT Gateways AWS pour permettre un accès Internet sortant aux ressources déployées dans les sous-réseaux privés du VPC, assurant ainsi une architecture hautement disponible et sécurisée.

## Vue d'ensemble

Les NAT Gateways (Network Address Translation) sont un composant essentiel d'une architecture VPC sécurisée, permettant aux ressources dans des sous-réseaux privés d'accéder à Internet sans être directement exposées. Ce module implémente une architecture multi-AZ pour garantir une haute disponibilité.

## Architecture réseau

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Internet                                   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Internet Gateway                              │
└───────────┬─────────────────────────────────────────┬───────────────────┘
            │                                         │
            ▼                                         ▼
┌───────────────────────┐                  ┌───────────────────────┐
│  Public Subnet AZ-a   │                  │  Public Subnet AZ-b   │
│                       │                  │                       │
│   ┌───────────────┐   │                  │   ┌───────────────┐   │
│   │  NAT Gateway  │   │                  │   │  NAT Gateway  │   │
│   │     AZ-a      │   │                  │   │     AZ-b      │   │
│   └───────┬───────┘   │                  │   └───────┬───────┘   │
│           │           │                  │           │           │
└───────────┼───────────┘                  └───────────┼───────────┘
            │                                         │
            ▼                                         ▼
┌───────────────────────┐                  ┌───────────────────────┐
│  Private Subnet AZ-a  │                  │  Private Subnet AZ-b  │
│                       │                  │                       │
│   ┌───────────────┐   │                  │   ┌───────────────┐   │
│   │  EKS Nodes    │   │                  │   │  EKS Nodes    │   │
│   │  MongoDB      │   │                  │   │  MongoDB      │   │
│   │  Services     │   │                  │   │  Services     │   │
│   └───────────────┘   │                  │   └───────────────┘   │
│                       │                  │                       │
└───────────────────────┘                  └───────────────────────┘
```

## Fonctionnalités principales

1. **Haute disponibilité**
   - Déploiement d'une NAT Gateway dans chaque zone de disponibilité
   - Isolation du trafic sortant par AZ pour éviter les points de défaillance uniques

2. **Sécurité renforcée**
   - Masquage des adresses IP privées des ressources internes
   - Protection contre les connexions entrantes non sollicitées
   - Contrôle du trafic sortant au niveau réseau

3. **Performance optimisée**
   - Bande passante adaptative jusqu'à 45 Gbps
   - Gestion automatique de la mise à l'échelle par AWS

## Ressources déployées

Ce module crée les ressources suivantes:

- **Elastic IP (EIP)** - Une adresse IP publique statique par zone de disponibilité
- **NAT Gateway** - Une passerelle NAT par zone de disponibilité, placée dans un sous-réseau public

## Bonnes pratiques implémentées

1. **Architecture multi-AZ**
   - NAT Gateway dédiée dans chaque AZ pour isoler les impacts en cas de défaillance d'une AZ
   - Réduction du trafic inter-AZ pour optimiser les coûts et les performances

2. **Organisation des ressources**
   - Nommage cohérent avec le reste de l'infrastructure
   - Tagging complet pour faciliter la gestion des coûts et les audits

3. **Optimisation des coûts**
   - Utilisation efficace des NAT Gateways (facturation horaire + données traitées)
   - Dimensionnement adapté aux besoins de l'application

## Variables d'entrée

| Nom | Description | Type | Obligatoire |
|-----|-------------|------|------------|
| availability_zones | Liste des zones de disponibilité où déployer les NAT Gateways | list(string) | Oui |
| public_subnet_ids | Liste des IDs des sous-réseaux publics où placer les NAT Gateways | list(string) | Oui |
| project_name | Nom du projet pour le tagging des ressources | string | Oui |
| environment | Environnement (production, staging, development) | string | Oui |
| vpc_id | ID du VPC | string | Oui |

## Sorties

| Nom | Description |
|-----|-------------|
| nat_gateway_ids | Liste des IDs des NAT Gateways créées (une par zone de disponibilité) |
| eip_ids | Liste des IDs des adresses IP Élastiques associées aux NAT Gateways |

## Utilisation

```hcl
module "nat" {
  source             = "./modules/nat"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnet_ids  = module.vpc.public_subnet_ids
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
}
```

## Intégration avec d'autres modules

Ce module NAT Gateway s'intègre étroitement avec:

- **Module VPC**: Utilise les sous-réseaux publics créés par le module VPC
- **Module Route**: Les tables de routage des sous-réseaux privés pointent vers ces NAT Gateways
- **Module EKS**: Les nœuds Kubernetes utilisent ces NAT Gateways pour l'accès Internet sortant

## Considérations de coût

Les NAT Gateways AWS génèrent deux types de coûts:
1. Frais horaires pour chaque NAT Gateway déployée (~0.045$ par heure, soit ~32$ par mois)
2. Frais par Go de données traitées (~0.045$ par Go)

Pour une architecture à 3 zones de disponibilité, cela représente environ 96$ par mois de frais fixes, plus les coûts variables basés sur l'utilisation.

## Évolution future

Ce module pourrait être étendu avec:

- Intégration avec AWS CloudWatch pour la surveillance des métriques de trafic
- Automatisation du basculement en cas de défaillance d'une NAT Gateway
- Configuration de VPC Flow Logs spécifiques pour analyser le trafic sortant