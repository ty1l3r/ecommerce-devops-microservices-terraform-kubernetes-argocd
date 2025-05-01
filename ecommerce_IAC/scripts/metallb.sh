#!/bin/bash
#-----------------------------------------------------------------
# Script d'installation et configuration de MetalLB
# Auteur: Tyler
# Dernière mise à jour: Avril 2025
#
# Description:
#   Ce script installe et configure MetalLB, un équilibreur de charge
#   pour Kubernetes fonctionnant sur des environnements bare-metal.
#   Il supprime également Traefik s'il est présent pour éviter les conflits
#   et configure MetalLB pour utiliser une plage d'adresses IP spécifique.
#
# Utilisation:
#   ./metallb.sh
#
# Prérequis:
#   - Un cluster Kubernetes fonctionnel (K3s)
#   - Helm installé et configuré
#   - Remplacer 'YOURIP' par l'adresse IP externe attribuée à votre instance
#-----------------------------------------------------------------

echo "Installation de MetalLB"

#------------------------------------------------------------------------
# SUPPRESSION DE TRAEFIK (SI PRÉSENT)
#------------------------------------------------------------------------
# Traefik est installé par défaut avec K3s et peut créer des conflits avec 
# d'autres contrôleurs d'entrée comme Nginx Ingress

# Vérification et suppression Traefik si présent
if kubectl -n kube-system get helmcharts.helm.cattle.io traefik &>/dev/null; then
    echo "Suppression de Traefik nécessaire..."
    kubectl -n kube-system delete helmcharts.helm.cattle.io traefik-crd 2>/dev/null || true
    kubectl -n kube-system delete helmcharts.helm.cattle.io traefik 2>/dev/null || true
    kubectl -n kube-system delete service traefik 2>/dev/null || true
    kubectl -n kube-system delete deployment traefik 2>/dev/null || true
    sleep 20
else
    echo "Traefik déjà supprimé"
fi

#------------------------------------------------------------------------
# INSTALLATION DE METALLB
#------------------------------------------------------------------------
# Déploiement du contrôleur MetalLB via Helm

echo "Installation de MetalLB..."
helm repo add metallb https://metallb.github.io/metallb --force-update
helm repo update
helm upgrade --install metallb metallb/metallb \
    --namespace metallb-system \
    --create-namespace \
    --wait || exit 1

#------------------------------------------------------------------------
# CONFIGURATION DE L'ADRESSAGE IP
#------------------------------------------------------------------------
# Création des ressources personnalisées pour définir le pool d'adresses IP
# et l'annonce de niveau 2 pour l'attribution d'adresses IP aux services

echo "Configuration de MetalLB..."
cat <<'EOF' | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - YOURIP/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advert
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF

#------------------------------------------------------------------------
# VÉRIFICATION DU DÉPLOIEMENT
#------------------------------------------------------------------------
# Attente que les pods MetalLB soient prêts et vérification de leur état

echo "Attente des pods MetalLB..."
kubectl wait --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s || exit 1

if kubectl get pods -n metallb-system -l app.kubernetes.io/component=controller | grep -q Running; then
    echo "MetalLB installé et fonctionnel"
else
    echo "Échec de l'installation MetalLB"
    kubectl get pods -n metallb-system
    exit 1
fi

echo "Installation de MetalLB terminée"