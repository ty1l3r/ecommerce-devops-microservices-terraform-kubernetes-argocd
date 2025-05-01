# Module Security Group - Isolation Réseau pour E-commerce

Ce module Terraform définit les groupes de sécurité AWS nécessaires pour isoler et protéger les différents composants de l'infrastructure e-commerce dans le VPC.

## Vue d'ensemble

Les groupes de sécurité agissent comme des pare-feu virtuels pour contrôler le trafic réseau entre les composants de l'infrastructure. Notre module implémente une stratégie de sécurité en profondeur avec le principe du moindre privilège.

## Groupes de Sécurité Créés

### MongoDB Security Group

Ce groupe de sécurité protège les instances MongoDB qui stockent les données persistantes des microservices :

- **Ingress**: Autorise uniquement le trafic depuis les nœuds EKS sur le port 27017 (MongoDB)
- **Egress**: Permet tout trafic sortant pour les mises à jour et la résolution DNS

### Services Security Group

Ce groupe de sécurité appliqué aux microservices de l'application (customers, products, shopping) :

- **Ingress**: Autorise le trafic depuis les nœuds EKS sur les ports 8001-8003 (API services)
- **Egress**: Permet tout trafic sortant pour les appels API externes

## Architecture de Sécurité

```
┌───────────────────────────────────────────────────┐
│                     Internet                      │
└───────────────────────────┬───────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────┐
│               AWS Load Balancer (ALB)             │
└───────────────────────────┬───────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────┐
│           NGINX Ingress Controller (EKS)          │
└───────────────────────────┬───────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────┐
│         Services Security Group (8001-8003)       │
├───────────────┬───────────────────┬───────────────┤
│ Customer API  │    Product API    │  Shopping API │
└───────┬───────┴────────┬──────────┴───────┬───────┘
        │                │                  │
        ▼                ▼                  ▼
┌───────────────────────────────────────────────────┐
│           MongoDB Security Group (27017)          │
├───────────────┬───────────────────┬───────────────┤
│ Customer DB   │    Product DB     │  Shopping DB  │
└───────────────┴───────────────────┴───────────────┘
```

## Bonnes Pratiques Implémentées

1. **Principe du Moindre Privilège** : Chaque composant n'a accès qu'aux ressources dont il a strictement besoin.
2. **Isolation des Services** : Les services sont isolés les uns des autres pour limiter la propagation des compromissions.
3. **Contrôle Granulaire** : Les règles d'accès sont définies au niveau des ports et protocoles spécifiques.
4. **Documentation Détaillée** : Chaque règle est documentée pour faciliter l'audit de sécurité.

## Utilisation

```hcl
module "security_groups" {
  source = "./modules/sg"
  
  vpc_id                     = module.vpc.vpc_id
  project_name               = var.project_name
  environment                = var.environment
  eks_nodes_security_group_id = module.eks.nodes_security_group_id
}
```

## Variables d'entrée

| Nom | Description | Type | Obligatoire |
|-----|-------------|------|------------|
| vpc_id | ID du VPC où les security groups seront créés | string | Oui |
| project_name | Nom du projet | string | Oui |
| environment | Environnement (production, staging, development) | string | Oui |
| eks_nodes_security_group_id | ID du security group des nodes EKS | string | Oui |
| tags | Tags additionnels à appliquer aux ressources | map(string) | Non |

## Sorties

| Nom | Description |
|-----|-------------|
| mongodb_sg_id | ID du security group MongoDB |
| services_sg_id | ID du security group services |

## Extension future

Le module peut être étendu pour prendre en charge des besoins de sécurité supplémentaires :

- Ajout de règles pour RabbitMQ
- Règles pour les caches Redis
- Intégration avec AWS WAF pour la protection des API
- Règles spécifiques pour les sessions administrateurs

## Conformité et Audit

Les groupes de sécurité sont conçus pour faciliter la conformité avec les normes de sécurité communes comme:
- PCI DSS (pour le traitement des paiements)
- GDPR (pour les données personnelles des clients)
- ISO 27001 (gestion de la sécurité de l'information)