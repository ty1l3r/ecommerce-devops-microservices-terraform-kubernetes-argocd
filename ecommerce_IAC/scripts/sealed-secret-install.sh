#!/bin/bash
#-----------------------------------------------------------------
# Script d'installation de Sealed Secrets
# Auteur: Tyler
# Dernière mise à jour: Avril 2025
#
# Description:
#   Ce script installe et configure Sealed Secrets, un outil qui permet 
#   de stocker des secrets Kubernetes de manière sécurisée dans un dépôt Git.
#   Il installe à la fois le contrôleur Sealed Secrets dans le cluster
#   et l'outil kubeseal CLI pour la génération des secrets scellés.
#
# Utilisation:
#   ./sealed-secret-install.sh
#
# Prérequis:
#   - Un cluster Kubernetes avec Helm configuré
#   - Droits sudo pour installer le binaire kubeseal
#-----------------------------------------------------------------

echo "Installation Sealed Secrets"

#------------------------------------------------------------------------
# INSTALLATION DU CONTRÔLEUR SEALED SECRETS
#------------------------------------------------------------------------
# Installe le contrôleur Sealed Secrets via Helm dans le namespace kube-system

echo "Installation..."
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
    --namespace kube-system \
    --create-namespace \
    --wait || exit 1

#------------------------------------------------------------------------
# INSTALLATION DE KUBESEAL CLI
#------------------------------------------------------------------------
# Télécharge et installe le client kubeseal CLI utilisé pour sceller les secrets

echo "Installation kubeseal..."
KUBESEAL_VERSION="0.24.4"
wget "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf "kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz" kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm -f kubeseal "kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"

echo "Installation terminée"