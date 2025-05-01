# Scripts d'infrastructure Kubernetes

## Présentation

Ce répertoire contient un ensemble de scripts Bash destinés à la configuration et au déploiement de l'infrastructure Kubernetes nécessaire pour la plateforme e-commerce. Ces scripts permettent d'automatiser l'installation et la configuration des composants essentiels dans les environnements de développement (VM) et de production (AWS).

Les scripts sont directement injectés dans le pipeline CI/CD via les jobs définis dans le fichier `.gitlab-ci.yml`, ce qui permet une exécution automatisée lors des déploiements et assure la cohérence entre les environnements.

## Organisation des scripts

Les scripts sont conçus pour être exécutés dans un ordre spécifique pour établir l'infrastructure complète :

### Scripts de base
- **helm-install.sh** : Installation et mise à jour de Helm, le gestionnaire de paquets Kubernetes
- **metallb.sh** : Installation et configuration de MetalLB pour le support LoadBalancer dans l'environnement VM

### Scripts d'ingress
- **nginx-ingress-vm.sh** : Installation du contrôleur Nginx Ingress pour l'environnement VM local
- **nginx-ingress-aws.sh** : Installation du contrôleur Nginx Ingress pour l'environnement AWS EKS

### Scripts de sécurité
- **cert-manager.sh** : Installation de cert-manager pour la gestion automatisée des certificats TLS
- **cluster-issuer.sh** : Configuration des émetteurs Let's Encrypt pour les certificats TLS
- **sealed-secret-install.sh** : Installation du contrôleur Sealed Secrets pour la gestion sécurisée des secrets

### Scripts de gestion des secrets
- **sealed-secret.sh** : Génération des secrets scellés pour l'environnement de développement
- **sealed-secret-prod.sh** : Génération des secrets scellés pour l'environnement de production
- **sealed-secret-backup.sh** : Sauvegarde des clés de chiffrement des secrets scellés pour le développement
- **sealed-secret-backup-prod.sh** : Sauvegarde des clés de chiffrement des secrets scellés pour la production
- **sealed-secret-install-prod.sh** : Installation de Sealed Secrets dans l'environnement de production

### Scripts d'initialisation des données
- **init-data.sh** : Initialisation des données de démonstration pour l'environnement de développement
- **init-data-staging.sh** : Initialisation des données de démonstration pour l'environnement de staging
- **init-data-prod.sh** : Initialisation des données initiales pour l'environnement de production

### Scripts de maintenance
- **destroy.sh** : Nettoyage des ressources Kubernetes avant destruction de l'infrastructure

## Flux d'exécution typique

1. Installation de Helm (`helm-install.sh`)
2. Configuration de MetalLB pour l'environnement VM (`metallb.sh`)
3. Installation du contrôleur d'ingress approprié (`nginx-ingress-vm.sh` ou `nginx-ingress-aws.sh`)
4. Installation de cert-manager (`cert-manager.sh`)
5. Configuration des émetteurs de certificats (`cluster-issuer.sh`)
6. Installation de Sealed Secrets (`sealed-secret-install.sh`)
7. Génération des secrets scellés (`sealed-secret.sh` ou `sealed-secret-prod.sh`)
8. Initialisation des données (`init-data.sh`, `init-data-staging.sh` ou `init-data-prod.sh`)

## Intégration avec le pipeline CI/CD

Ces scripts sont directement injectés dans les pipelines définis dans `.gitlab-ci.yml` via la commande `./scripts/script-name.sh` sans nécessiter d'étape intermédiaire. Cette approche présente plusieurs avantages :

- **Exécution immédiate** : Les scripts sont exécutés directement dans le contexte du runner GitLab
- **Traçabilité complète** : Les sorties des scripts sont capturées dans les logs de pipeline
- **Accès aux variables d'environnement** : Les scripts peuvent utiliser les variables définies dans le pipeline
- **Échec explicite** : Un code de retour non-zéro du script arrête automatiquement le job en cours

Ils sont conçus pour être idempotents, ce qui signifie qu'ils peuvent être exécutés plusieurs fois sans effets secondaires indésirables.

## Notes de sécurité

- Les scripts de gestion des secrets utilisent Sealed Secrets pour chiffrer les secrets avant leur stockage dans Git
- Les clés de chiffrement sont sauvegardées pour permettre le déchiffrement des secrets en cas de besoin
- Les certificats TLS sont gérés automatiquement par cert-manager via Let's Encrypt

## Auteur

Tyler - Avril 2025