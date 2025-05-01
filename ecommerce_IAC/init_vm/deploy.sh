#!/bin/bash
#-----------------------------------------------------------------
# Script principal de déploiement d'environnement de développement
# Auteur: Tyler
# Dernière mise à jour: Janvier 2025
#
# Description:
#   Ce script orchestre le déploiement complet d'un environnement
#   de développement sur une VM distante. Il coordonne l'exécution
#   séquentielle des scripts spécialisés pour:
#   1. Initialiser la machine (utilisateurs, SSH)
#   2. Installer les outils de base
#   3. Configurer Docker et le GitLab Runner
#
# Utilisation:
#   ./deploy.sh
#
# Prérequis:
#   - Un fichier password.txt contenant le mot de passe de la VM
#   - L'adresse IP de la VM cible configurée dans la variable REMOTE_HOST
#   - Les scripts d'initialisation présents dans le même répertoire
#-----------------------------------------------------------------

# Couleurs pour le feedback visuel
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # No Color

# Délimiteur visuel pour une meilleure lisibilité des logs
SEPARATOR="\n=====================================================\n"

# Variables de configuration de la connexion
REMOTE_USER="ubuntu"
REMOTE_HOST="IP_ADDRESS"  # À remplacer par l'adresse IP réelle de la VM
PASSWORD_FILE="password.txt"

# Vérification de la présence du fichier de mot de passe
if [ ! -f "$PASSWORD_FILE" ]; then
  echo -e "${RED}Le fichier de mot de passe $PASSWORD_FILE est manquant...FAIL${NC}"
  exit 1
fi

# Récupération du mot de passe depuis le fichier
REMOTE_PASS=$(cat "$PASSWORD_FILE")

echo -e "$SEPARATOR Lancement du déploiement de la machine distante $SEPARATOR"
#########################################################################
#       ÉTAPE 1 : INITIALISATION DE LA MACHINE AVEC INITIALISATION-VM   #
#########################################################################
echo -e "${GREEN}Étape 1 : Initialisation de la machine avec initialisation-vm.sh...${NC}"
# Exécution du script d'initialisation qui configure les utilisateurs et SSH
./initialisation-vm.sh
if [ $? -ne 0 ]; then
  echo -e "${RED}Échec de l'initialisation de la machine...FAIL${NC}"
  exit 1
fi
echo -e "${GREEN}Initialisation de la machine réussie...PASS${NC}"

#########################################################################
#   ÉTAPE 2 : INSTALLATION DES OUTILS DE BASE AVEC PACKAGE-VM.SH        #
#########################################################################
echo -e "${GREEN}Étape 2 : Installation des outils de base avec package-vm.sh...${NC}"
# Installation des dépendances et paquets système nécessaires
./package-vm.sh
if [ $? -ne 0 ]; then
  echo -e "${RED}Échec lors de l'installation des outils...FAIL${NC}"
  exit 1
fi

echo -e "${GREEN}Installation des outils de base réussie...PASS${NC}"

#########################################################################
#   ÉTAPE 3 : INSTALLATION DU DOCKER & K3S-RUNNER.SH                    #
#########################################################################

echo -e "${GREEN}Étape 3 : Installation du GitLab Runner avec k3s-runner.sh...${NC}"
# Configuration de Docker et des GitLab Runners pour l'intégration CI/CD
./k3s-runner.sh
if [ $? -ne 0 ]; then
  echo -e "${RED}Échec lors de l'installation du GitLab Runner...FAIL${NC}"
  exit 1
fi

echo -e "${GREEN}Installation du GitLab Runner réussie...PASS${NC}"

########################################################################
# DÉPLOIEMENT VM TERMINÉ AVEC SUCCÈS                                   #
########################################################################

echo -e "$SEPARATOR Déploiement terminé avec succès! $SEPARATOR"
# La VM est maintenant prête pour le déploiement de Kubernetes
# Si besoin, pour installer K3s, exécutez ensuite le script k3s-install.sh manuellement 
