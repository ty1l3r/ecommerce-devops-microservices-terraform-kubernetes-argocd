# Infrastructure as Code - Ecommerce GitOps Platform

Ce dépôt contient les configurations Infrastructure as Code (IaC) pour déployer et gérer l'infrastructure d'une application e-commerce basée sur une architecture GitOps. Nous utilisons Terraform pour définir et provisionner l'infrastructure sur AWS, ainsi que plusieurs modules pour configurer les composants nécessaires sur Kubernetes (EKS).

## Structure du Projet

- **terraform/** : Contient les configurations Terraform pour déployer l'infrastructure sur AWS.
  - **backend/** : Configuration du backend S3 et DynamoDB pour l'état Terraform.
  - **modules/** : Modules Terraform réutilisables pour chaque composant de l'infrastructure.
    - **vpc/** : Configuration du réseau VPC, subnets, et routage.
    - **subnets/** : Configuration des sous-réseaux publics et privés.
    - **nat/** : NAT Gateways pour l'accès internet des ressources privées.
    - **eks/** : Cluster Kubernetes géré par AWS (EKS).
    - **iam/** : Rôles et politiques IAM pour les différents services.
    - **iam-irsa/** : Configuration IAM pour les Service Accounts Kubernetes (IRSA).
    - **s3/** : Buckets S3 pour les backups, logs, et l'état Terraform.
    - **ebs/** : Volumes EBS persistants pour les bases de données MongoDB et RabbitMQ.
    - **sg/** : Security Groups pour contrôler l'accès réseau.
    - **helm/** : Déploiements d'applications via Helm charts.
    - **argocd/** : Configuration d'ArgoCD pour le GitOps.
    - **commons/** : Ressources partagées comme les tags et les conventions de nommage.
- **scripts/** : Scripts bash pour l'installation et la configuration de composants.
- **init_vm/** : Scripts pour initialiser les VMs de développement/staging.

## Composants Principaux

### Infrastructure AWS
- **VPC & Networking**: VPC dédié avec subnets publics/privés et NAT Gateways
- **EKS**: Cluster Kubernetes managé avec support IRSA (IAM Roles for Service Accounts)
- **Storage**:
  - **S3**: Buckets pour backups (Velero), logs (Fluentd) et état Terraform
  - **EBS**: Volumes persistants pour MongoDB (customers, products, shopping) et RabbitMQ

### Kubernetes & GitOps
- **ArgoCD**: Outil GitOps pour le déploiement continu basé sur des manifestes Git
- **Monitoring**: Prometheus et Grafana pour la surveillance et la visualisation
- **Backup/Restore**: Velero pour la sauvegarde et restauration du cluster
- **Logging**: Fluentd pour la collection et l'exportation des logs vers S3
- **Security**: 
  - Sealed Secrets pour le stockage sécurisé des secrets
  - Cert-Manager pour la gestion automatique des certificats TLS
- **Ingress**: Nginx Ingress Controller pour l'accès externe aux services

## Configuration du Backend Terraform

Le projet utilise un backend S3 avec DynamoDB pour le verrouillage d'état:
```
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

## Sauvegarde et Restauration

### État Terraform
```bash
# Liste des backups disponibles
aws s3 ls s3://red-project-production-tfstate-backup/

# Création sauvegarde de sécurité
aws s3 cp \
    s3://red-project-production-tfstate/terraform.tfstate \
    s3://red-project-production-tfstate/terraform.tfstate.pre-restore.$(date +%Y%m%d_%H%M)

# Restauration depuis backup (remplacer YYYY-MM-DD_HH-MM par la date voulue)
aws s3 cp \
    s3://red-project-production-tfstate-backup/YYYY-MM-DD_HH-MM/terraform.tfstate \
    s3://red-project-production-tfstate/terraform.tfstate

# Vérification
cd terraform
terraform init
terraform plan
```

### Données de l'Application
Les sauvegardes des données de l'application sont gérées par Velero, qui sauvegarde:
- Les volumes MongoDB pour chaque service (customers, products, shopping)
- Les configurations du cluster et des namespaces
- Les backups sont stockés dans le bucket S3: `${project_name}-${environment}-backup-2`

## Destruction de l'Infrastructure

```bash
terraform init
terraform workspace select production
terraform destroy
```

## Runners & Environnement CI/CD
- Runners configurés sur VM de développement
- Variables d'environnement à configurer dans GitLab:
  - `KUBE_CONFIG_DEV`: Fichier kubeconfig pour l'environnement de développement (protégé)
  - `KUBE_CONFIG_STAGING`: Fichier kubeconfig pour l'environnement de staging (protégé)

## En cas de réinitialisation de la VM
```bash
# Obtenir l'adresse du serveur K3s
sudo cat /etc/rancher/k3s/k3s.yaml | grep server

# Générer le fichier kubeconfig en base64 pour GitLab
sudo cat /etc/rancher/k3s/k3s.yaml | base64 -w 0

# Script pour faciliter l'obtention du kubeconfig encodé
cat << 'EOF' > /tmp/get-kubeconfig.sh
#!/bin/bash
sudo cat /etc/rancher/k3s/k3s.yaml | base64 -w 0
EOF

chmod +x /tmp/get-kubeconfig.sh
/tmp/get-kubeconfig.sh > /tmp/kubeconfig.base64
cat /tmp/kubeconfig.base64