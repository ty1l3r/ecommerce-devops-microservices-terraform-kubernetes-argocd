# Backend Terraform pour la Plateforme E-commerce

Ce dossier contient la configuration du backend Terraform pour le stockage sécurisé de l'état d'infrastructure et le verrouillage d'état. Cette configuration est cruciale pour le travail d'équipe et la sécurité de votre infrastructure as code.

## Vue d'ensemble

Le backend Terraform est configuré pour utiliser:
- Un bucket S3 pour le stockage des fichiers d'état
- Une table DynamoDB pour le verrouillage d'état et la prévention des modifications concurrentes

## Architecture

```
   ┌─────────────────┐         ┌────────────────────┐
   │                 │         │                    │
   │  Terraform CLI  ├────────►│  S3 Bucket         │
   │                 │         │  (État Terraform)  │
   └────────┬────────┘         └────────────────────┘
            │
            │                  ┌────────────────────┐
            │                  │                    │
            └─────────────────►│  DynamoDB Table    │
                               │  (Verrouillage)    │
                               └────────────────────┘
```

## Composants

### Bucket S3 (`aws_s3_bucket.terraform_state`)
- **Nom**: `red-project-production-2-tfstate`
- **Fonction**: Stockage persistant du fichier d'état Terraform (.tfstate)
- **Caractéristiques**:
  - Versionnement automatique pour l'historique des modifications
  - Chiffrement côté serveur (AES256)
  - Blocage de tout accès public
  - Tags pour suivi et gestion des ressources

### Table DynamoDB (`aws_dynamodb_table.terraform_locks`)
- **Nom**: `red-project-production-2-tfstate-lock`
- **Fonction**: Verrouillage des opérations Terraform pour éviter les modifications simultanées
- **Caractéristiques**:
  - Clé primaire "LockID" utilisée par Terraform pour le verrouillage
  - Mode de facturation à la demande (pay-per-request)
  - Tags pour suivi et gestion des ressources

## Configuration

### Variables configurables

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `aws_region` | Région AWS pour le déploiement | `eu-west-3` (Paris) |
| `environment` | Nom de l'environnement | `production` |
| `project_name` | Nom du projet | `red-project` |
| `availability_zones` | Zones de disponibilité AWS | `["eu-west-3a", "eu-west-3b", "eu-west-3c"]` |

### Sorties (Outputs)

| Output | Description |
|--------|-------------|
| `state_bucket_name` | Nom du bucket S3 |
| `dynamodb_table_name` | Nom de la table DynamoDB |
| `state_bucket_arn` | ARN du bucket S3 |
| `dynamodb_table_arn` | ARN de la table DynamoDB |

## Utilisation

### Configuration du backend

Pour utiliser ce backend, ajoutez la configuration suivante dans votre fichier `providers.tf` :

```terraform
terraform {
  backend "s3" {
    bucket         = "red-project-production-2-tfstate"
    key            = "terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "red-project-production-2-tfstate-lock"
    encrypt        = true
  }
}
```

### Initialisation

Pour initialiser le backend:

```bash
# Création de l'infrastructure du backend (S3 + DynamoDB)
cd terraform/backend
terraform init
terraform apply

# Utilisation du backend pour le projet principal
cd ..
terraform init -backend-config=backend/backend-production.tfvars
```

### Bonnes pratiques

- Créez des backups réguliers de l'état avec:
  ```bash
  aws s3 cp s3://red-project-production-2-tfstate/terraform.tfstate s3://red-project-production-tfstate-backup/$(date +%Y-%m-%d_%H-%M)/terraform.tfstate
  ```

- Verrouillez le bucket S3 en production avec la politique `prevent_destroy = true`.

## Sécurité

Cette configuration implémente plusieurs bonnes pratiques de sécurité:

1. **Chiffrement des données** - Toutes les données d'état sont chiffrées au repos avec AES-256.
2. **Isolation d'accès** - Blocage total de l'accès public au bucket S3.
3. **Versionnement** - Conservation de l'historique des états pour faciliter la récupération.
4. **Verrouillage** - Prévention des modifications concurrentes qui pourraient corrompre l'état.

## Référence

- [Documentation Terraform sur les backends S3](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Bucket Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [AWS DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)