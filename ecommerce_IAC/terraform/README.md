# Infrastructure Terraform pour la Plateforme E-commerce

Ce répertoire contient les définitions Terraform pour déployer l'infrastructure AWS complète de notre plateforme e-commerce basée sur Kubernetes et suivant les principes GitOps.

## Architecture de l'Infrastructure

L'infrastructure est organisée de manière modulaire et déployée dans un ordre précis pour respecter les dépendances:

1. **Configuration commune** (`commons`) - Tags et conventions de nommage
2. **Infrastructure réseau**:
   - VPC - Réseau virtuel isolé
   - Subnets publics - Pour les services accessibles depuis l'extérieur
   - NAT Gateways - Pour l'accès Internet depuis les ressources privées
   - Subnets privés - Pour les services internes (EKS, bases de données)
3. **Stockage**:
   - Buckets S3 - Pour les sauvegardes, logs et l'état Terraform
   - Volumes EBS - Stockage persistant pour MongoDB et RabbitMQ
4. **Gestion des identités et accès**:
   - IAM de base - Rôles et politiques pour les services AWS
   - IAM IRSA - Intégration des comptes de service Kubernetes avec IAM AWS
5. **Kubernetes (EKS)**:
   - Cluster EKS - Héberge notre application e-commerce
   - Node groups - Instances de calcul pour le cluster
6. **GitOps et Surveillance**:
   - ArgoCD - Déploiement continu basé sur Git
   - Helm Charts - Installation de composants Kubernetes essentiels

## Structure des modules

```
terraform/
├── main.tf              # Point d'entrée principal
├── variables.tf         # Définition des variables
├── outputs.tf           # Valeurs de sortie
├── providers.tf         # Configuration des providers
├── versions.tf          # Versions requises
├── backend/             # Configuration du backend S3
└── modules/             # Modules réutilisables
    ├── argocd/          # Configuration d'ArgoCD pour GitOps
    ├── commons/         # Tags et conventions de nommage partagés
    ├── ebs/             # Volumes persistants pour les bases de données
    ├── eks/             # Cluster Kubernetes géré
    ├── helm/            # Déploiements d'applications via Helm
    ├── iam/             # Rôles et politiques IAM
    ├── iam-irsa/        # Integration IAM pour Service Accounts
    ├── nat/             # NAT Gateways pour l'accès Internet
    ├── s3/              # Buckets S3 pour backups, logs et Terraform state
    ├── sg/              # Security Groups pour le contrôle d'accès réseau
    ├── subnets/         # Configuration de sous-réseaux
    └── vpc/             # Réseau virtuel privé
```

## Flux de déploiement

L'infrastructure est déployée selon un ordre précis défini par les dépendances dans le fichier `main.tf`:

1. Création des ressources de base (VPC, sous-réseaux, NAT Gateways)
2. Configuration du stockage S3 pour les sauvegardes et logs
3. Configuration des rôles IAM nécessaires
4. Déploiement du cluster EKS dans les sous-réseaux privés
5. Configuration de l'intégration IAM pour les comptes de service Kubernetes (IRSA)
6. Installation d'ArgoCD pour la gestion GitOps
7. Déploiement des composants additionnels via Helm (monitoring, logging, etc.)

## Variables importantes

| Variable | Description |
|----------|-------------|
| `project_name` | Nom du projet, utilisé pour préfixer les ressources |
| `environment` | Environnement de déploiement (dev, staging, production) |
| `aws_region` | Région AWS où déployer les ressources |
| `availability_zones` | Zones de disponibilité à utiliser |
| `domain_name` | Nom de domaine pour les ingress |
| `mongodb_storage_class` | Classe de stockage pour les volumes MongoDB |
| `grafana_password` | Mot de passe pour l'interface Grafana |
| `cert_manager_email` | Email pour les notifications Let's Encrypt |

## Composants installés via Helm

Les composants suivants sont installés automatiquement via le module `helm`:

- **NGINX Ingress Controller** - Gestion du trafic entrant
- **Cert-Manager** - Gestion automatique des certificats TLS
- **Prometheus & Grafana** - Surveillance et visualisation
- **Velero** - Sauvegarde et restauration du cluster
- **Fluentd** - Collecte et exportation des logs

## Utilisation

### Prérequis

- Terraform v1.0+
- AWS CLI configuré avec les bonnes permissions
- kubectl pour interagir avec le cluster après sa création

### Initialisation

```bash
cd terraform
terraform init -backend-config=backend/backend-production.tfvars
terraform workspace select production
```

### Planification

```bash
terraform plan -var-file=vars/production.tfvars
```

### Application

```bash
terraform apply -var-file=vars/production.tfvars
```

### Configuration de kubectl

Une fois l'infrastructure déployée, configurez kubectl pour interagir avec le cluster EKS:

```bash
aws eks update-kubeconfig --name <project_name>-<environment>-eks --region <aws_region>
```

## Sauvegarde et restauration

Les sauvegardes et restaurations sont gérées par Velero qui est configuré pour utiliser le bucket S3 créé par le module `s3`. Pour plus de détails sur les opérations de sauvegarde et restauration, consultez la documentation de Velero.