#!/bin/bash
#-----------------------------------------------------------------
# Script d'installation de cert-manager
# Auteur: Tyler
# Dernière mise à jour: Mars 2025
#
# Description:
#   Ce script installe cert-manager dans le cluster Kubernetes.
#   Cert-manager est un contrôleur qui automatise la gestion des
#   certificats TLS, permettant notamment l'intégration avec Let's Encrypt
#   pour des certificats HTTPS valides et leur renouvellement automatique.
#
# Utilisation:
#   ./cert-manager.sh
#
# Prérequis:
#   - Un cluster Kubernetes fonctionnel
#   - Helm installé et configuré
#-----------------------------------------------------------------

echo "Installation de cert-manager"

#------------------------------------------------------------------------
# INSTALLATION DE CERT-MANAGER
#------------------------------------------------------------------------
# Installation via Helm chart avec les CRDs inclus

echo "Ajout repo Helm..."
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update

echo "Installation cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.13.3 \
    --set installCRDs=true \
    --wait \
    --timeout 3m

if [ $? -eq 0 ]; then
    echo "Installation complète"
else
    echo "Échec de l'installation"
    exit 1
fi