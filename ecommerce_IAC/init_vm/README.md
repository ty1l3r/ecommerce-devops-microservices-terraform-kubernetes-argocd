# Scripts d'initialisation et de configuration pour environnement de développement

## Présentation

Ce dossier contient un ensemble de scripts Bash destinés à la configuration rapide et automatisée d'une machine virtuelle pour l'environnement de développement de la plateforme e-commerce. Ces scripts ont été spécifiquement développés pour contourner les limitations des scripts d'installation automatique fournis par l'hébergeur 1&1, permettant ainsi de déployer rapidement un environnement Kubernetes opérationnel.

## Architecture des scripts

L'automatisation est structurée de manière séquentielle, chaque script ayant une responsabilité unique :

- **deploy.sh** : Script d'orchestration principal qui coordonne l'exécution séquentielle des autres scripts
- **initialisation-vm.sh** : Configuration sécurisée de l'accès SSH et création d'un utilisateur non-root avec privilèges sudo
- **package-vm.sh** : Installation des outils système essentiels (nano, tree, curl, htop, net-tools, nginx)
- **firewall-vm.sh** : Configuration du pare-feu UFW avec ouverture sélective des ports nécessaires pour Kubernetes
- **k3s-runner.sh** : Installation de Docker et configuration des GitLab Runners (Docker et Shell) pour l'intégration CI/CD
- **k3s-install.sh** : Déploiement d'un cluster Kubernetes léger (K3s) avec configuration personnalisée

## Prérequis

1. Une machine virtuelle Linux (Ubuntu) accessible via SSH
2. Un compte utilisateur avec accès root (temporaire, pour l'initialisation)
3. Un fichier `password.txt` contenant le mot de passe root initial
4. Une paire de clés SSH générée sur la machine locale

## Utilisation

1. Cloner ce dépôt sur votre machine locale
2. Modifier les variables d'adresse IP dans chaque script (`YOUR_IP_ADDRESS`) pour correspondre à votre VM
3. Créer un fichier `password.txt` avec le mot de passe root initial
4. Exécuter le script principal :
   ```bash
   ./deploy.sh
   ```

## Flux d'exécution

1. **Initialisation** : Configuration de l'accès SSH sécurisé et création d'un utilisateur non-root
2. **Installation des outils** : Déploiement des utilitaires système essentiels
3. **Configuration du pare-feu** : Mise en place des règles de sécurité réseau
4. **Installation des runners** : Configuration de l'environnement CI/CD avec GitLab Runners
5. **Déploiement K3s** : Installation du cluster Kubernetes léger

## Intégration avec le reste du projet

Ces scripts préparent l'environnement de développement pour :
- Le déploiement des microservices de la plateforme e-commerce (`ecommerce_APP`)
- L'exécution des pipelines CI/CD définis dans `.gitlab-ci.yml`
- Le test de l'infrastructure avant son déploiement en production sur AWS

## Sécurité

- L'authentification par mot de passe est désactivée après la configuration initiale
- L'accès SSH est sécurisé par authentification par clé
- Les permissions sont configurées selon le principe du moindre privilège
- Le pare-feu est configuré pour n'exposer que les ports nécessaires

## Notes

Ces scripts sont conçus pour un environnement de développement et peuvent nécessiter des ajustements pour un déploiement en production. Pour les environnements de production, référez-vous à la configuration Terraform dans le dossier parent.

## Auteur

Tyler - MARS 2025