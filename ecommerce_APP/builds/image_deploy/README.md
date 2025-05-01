# Image de Déploiement CI/CD pour E-commerce

## Vue d'ensemble

Cette image Docker personnalisée est conçue pour faciliter le déploiement et l'automatisation des opérations CI/CD de la plateforme E-commerce. Elle intègre tous les outils et utilitaires nécessaires pour orchestrer le déploiement dans un environnement AWS et Kubernetes.

## Fonctionnalités principales

- Image légère basée sur Amazon Linux 2
- Support complet AWS CLI pour l'interaction avec les services AWS
- Outils de manipulation de configuration Kubernetes et Helm
- Utilitaires de traitement de données YAML et JSON
- Base adaptée aux pipelines CI/CD GitOps

## Outils pré-installés

| Outil | Version | Description |
|-------|---------|-------------|
| AWS CLI | 2.13.13 | Interface en ligne de commande AWS pour l'interaction avec les services AWS |
| Helm | Dernière stable | Gestionnaire de packages Kubernetes |
| yq | v4.40.5 | Processeur YAML pour manipuler les fichiers de configuration |
| jq | Dernière stable | Processeur JSON pour le traitement des données |
| Git | Dernière stable | Gestion de versions pour le flux GitOps |
| Python 3 | Dernière stable | Support pour divers scripts d'automation |

## Utilisation

### Déploiement local

```bash
docker build -t deployment-image:latest .
docker run -it --rm \
  -v ~/.aws:/root/.aws \
  -v $(pwd):/app \
  deployment-image:latest
```

### Dans les pipelines CI/CD

```yaml
deploy:
  image: registry.example.com/deployment-image:latest
  script:
    - aws eks update-kubeconfig --name my-cluster --region eu-west-1
    - helm upgrade --install my-release ./prod_manifeste
```

## Variables d'environnement

L'image prend en charge toutes les variables d'environnement standard AWS et Kubernetes. Voici les principales :

| Variable | Description | Exemple |
|----------|-------------|---------|
| AWS_ACCESS_KEY_ID | Clé d'accès AWS | AKIA... |
| AWS_SECRET_ACCESS_KEY | Clé secrète AWS | 8Pgxt... |
| AWS_DEFAULT_REGION | Région AWS par défaut | eu-west-1 |
| KUBECONFIG | Chemin vers le fichier kubeconfig | /app/.kubeconfig |

## Personnalisation

L'image peut être personnalisée pour ajouter des outils supplémentaires en modifiant le Dockerfile :

```dockerfile
# Installation d'outils supplémentaires
RUN pip3 install awsebcli
```

## Bonnes pratiques de sécurité

- Utilisez les rôles IAM lors du déploiement sur AWS ECS/EKS
- Stockez les identifiants AWS dans des secrets sécurisés de votre système CI/CD
- Actualisez régulièrement l'image pour obtenir les derniers correctifs de sécurité
- Effectuez des analyses de vulnérabilités sur l'image avant de la pousser vers un registre

## Intégration avec ArgoCD

L'image est optimisée pour fonctionner avec ArgoCD dans notre flux GitOps :

1. Les pipelines CI utilisent cette image pour construire et pousser les artefacts
2. ArgoCD détecte les changements et synchronise l'infrastructure
3. Les applications sont déployées via Helm sur Kubernetes

## Maintenance

Cette image est maintenue régulièrement avec les mises à jour de versions pour :
- AWS CLI
- yq
- Helm
- Dépendances de sécurité

## Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.