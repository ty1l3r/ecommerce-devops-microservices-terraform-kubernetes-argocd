#!/bin/bash
#-----------------------------------------------------------------
# Script d'installation de Nginx Ingress Controller pour AWS
# Auteur: Tyler
# Dernière mise à jour: Avril 2025
#
# Description:
#   Ce script installe et configure Nginx Ingress Controller sur un
#   environnement AWS EKS. Il configure le contrôleur pour utiliser un
#   Network Load Balancer (NLB) AWS et vérifie que l'installation est
#   fonctionnelle.
#
# Utilisation:
#   ./nginx-ingress-aws.sh
#
# Prérequis:
#   - Un cluster EKS fonctionnel
#   - Helm installé et configuré
#   - Accès AWS configuré avec les permissions IAM appropriées
#-----------------------------------------------------------------

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"
SEPARATOR="\n=====================================================\n"

echo -e "$SEPARATOR Installation de Nginx Ingress (AWS) $SEPARATOR"

#------------------------------------------------------------------------
# INSTALLATION DE NGINX INGRESS CONTROLLER
#------------------------------------------------------------------------
# Déploiement via Helm avec configuration spécifique pour AWS NLB

echo "Installation de Nginx Ingress..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
helm repo update && \
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
--namespace ingress-nginx \
--create-namespace \
--set controller.service.type=LoadBalancer \
--set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb || {
    echo -e "${RED}Échec de l'installation de Nginx${NC}"
    exit 1
}

#------------------------------------------------------------------------
# VÉRIFICATION DU DÉPLOIEMENT
#------------------------------------------------------------------------
# Attente que le pod du contrôleur soit prêt et opérationnel

echo "Attente que le pod Nginx soit prêt..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s || {
    echo -e "${RED}Le pod Nginx n'est pas devenu prêt${NC}"
    kubectl get pods -n ingress-nginx
    exit 1
}

echo -e "${GREEN}Installation de Nginx Ingress Controller réussie${NC}"