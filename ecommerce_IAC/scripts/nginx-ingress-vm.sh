#!/bin/bash
#-----------------------------------------------------------------
# Script d'installation de Nginx Ingress Controller pour VM
# Auteur: Tyler
# Dernière mise à jour: Avril 2025
#
# Description:
#   Ce script installe et configure Nginx Ingress Controller sur un
#   environnement VM local utilisant K3s et MetalLB. Il vérifie également
#   que l'adresse IP externe attendue est correctement attribuée au
#   service LoadBalancer Nginx.
#
# Utilisation:
#   ./nginx-ingress-vm.sh
#
# Prérequis:
#   - Un cluster K3s fonctionnel
#   - MetalLB installé et configuré
#   - Helm installé et configuré
#-----------------------------------------------------------------

echo "Installation de Nginx Ingress"

#------------------------------------------------------------------------
# INSTALLATION DE NGINX INGRESS CONTROLLER
#------------------------------------------------------------------------
# Configuration du contrôleur avec support des annotations de snippet
# et politique de trafic externe local pour une meilleure gestion des IPs sources

echo "Installation de Nginx Ingress..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
helm repo update && \
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
--namespace ingress-nginx \
--create-namespace \
--set controller.service.type=LoadBalancer \
--set controller.service.externalTrafficPolicy=Local \
--set controller.allowSnippetAnnotations=true \
--set controller.enableAnnotationSnippets=true || exit 1

#------------------------------------------------------------------------
# VÉRIFICATION DE L'ATTRIBUTION IP
#------------------------------------------------------------------------
# Attente et vérification que l'IP attendue (85.215.217.45) est bien
# attribuée au service LoadBalancer, avec 12 tentatives espacées de 10 secondes

echo "Attente attribution IP..."
for i in $(seq 1 12); do
    echo "Vérification IP (tentative $i/12)"
    IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ "$IP" = "85.215.217.45" ]; then
        echo "IP $IP attribuée"
        exit 0
    fi
    sleep 10
done

# En cas d'échec d'attribution de l'IP attendue
echo "Échec attribution IP"
kubectl describe svc -n ingress-nginx ingress-nginx-controller
exit 1