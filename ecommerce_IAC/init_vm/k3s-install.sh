#!/bin/bash
#-----------------------------------------------------------------
# Script d'installation et configuration de K3s (Kubernetes léger)
# Auteur: Tyler
# Dernière mise à jour: Janvier 2025
#
# Description:
#   Ce script installe et configure un cluster Kubernetes léger (K3s)
#   sur une VM distante. Il désactive certains composants par défaut
#   pour permettre une personnalisation ultérieure et configure
#   les permissions nécessaires pour les utilisateurs.
#
# Utilisation:
#   ./k3s-install.sh
#
# Prérequis:
#   - L'adresse IP de la VM cible configurée dans la variable REMOTE_HOST
#   - L'utilisateur exécutant le script doit avoir des privilèges sudo
#-----------------------------------------------------------------

# Variables de configuration
REMOTE_HOST="YOUT_IP_ADDRESS"  # À remplacer par l'adresse IP réelle de la VM
DESIRED_VERSION="v1.27.4+k3s1"  # Version spécifique de K3s à installer

echo "Installation K3s"

#------------------------------------------------------------------------
# INSTALLATION DU SERVEUR K3S
#------------------------------------------------------------------------
# Installation de K3s avec des options spécifiques:
# - Version spécifiée via DESIRED_VERSION
# - Mode de permissions du kubeconfig restreint (640)
# - Désactivation de Traefik (pour utiliser un autre ingress controller)
# - Désactivation de ServiceLB (pour utiliser MetalLB)
# - Désactivation de metrics-server (pour installer une version personnalisée)

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$DESIRED_VERSION sh -s - \
    --write-kubeconfig-mode 640 \
    --disable traefik \
    --disable servicelb \
    --disable metrics-server

#------------------------------------------------------------------------
# CONFIGURATION DES PERMISSIONS DE SÉCURITÉ
#------------------------------------------------------------------------
# Création d'un groupe dédié pour l'accès au fichier kubeconfig
# et ajout des utilisateurs pertinents à ce groupe pour la gestion du cluster

echo "Configuration permissions..."
sudo groupadd -f k3susers
sudo usermod -aG k3susers ubuntu
sudo usermod -aG k3susers gitlab-runner
sudo chown root:k3susers /etc/rancher/k3s/k3s.yaml
sudo chmod 640 /etc/rancher/k3s/k3s.yaml

#------------------------------------------------------------------------
# CONFIGURATION DU FICHIER KUBECONFIG
#------------------------------------------------------------------------
# Modification du fichier kubeconfig pour remplacer l'adresse localhost
# par l'adresse IP de la VM, permettant l'accès distant au cluster

echo "Configuration IP..."
sudo sed -i "s|127.0.0.1|$REMOTE_HOST|" /etc/rancher/k3s/k3s.yaml

#------------------------------------------------------------------------
# AFFICHAGE DU FICHIER KUBECONFIG ENCODÉ EN BASE64
#------------------------------------------------------------------------
# Utile pour copier la configuration et l'utiliser depuis une machine distante
# Le format base64 préserve le formatage YAML et facilite le transfert

echo "COPIER LE KUBECONFIG:"
sudo cat /etc/rancher/k3s/k3s.yaml | base64 -w 0