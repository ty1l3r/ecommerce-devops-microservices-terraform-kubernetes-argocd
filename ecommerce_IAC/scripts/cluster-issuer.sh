#!/bin/bash
#-----------------------------------------------------------------
# Script de configuration d'un ClusterIssuer pour cert-manager
# Auteur: Tyler
# Dernière mise à jour: Fevrier 2025
#
# Description:
#   Ce script crée un ClusterIssuer pour cert-manager qui utilise 
#   Let's Encrypt pour émettre des certificats TLS valides.
#   Il configure à la fois un émetteur de production et de staging,
#   avec une adresse email spécifiée pour les notifications.
#
# Utilisation:
#   ./cluster-issuer.sh [adresse_email]
#
# Prérequis:
#   - cert-manager installé et fonctionnel dans le cluster
#   - Kubectl configuré pour accéder au cluster
#-----------------------------------------------------------------

# Définition de la valeur par défaut pour l'adresse email
EMAIL=${1:-"example@example.com"}

echo "Configuration du ClusterIssuer cert-manager"

#------------------------------------------------------------------------
# CRÉATION DU CLUSTERISSUER LETSENCRYPT-STAGING
#------------------------------------------------------------------------
# Création d'un émetteur de certificats pour l'environnement de staging
# Utile pour les tests sans risquer les limites de taux de Let's Encrypt

echo "Création du ClusterIssuer pour Let's Encrypt Staging..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Vérification du statut du ClusterIssuer de staging
kubectl get clusterissuer letsencrypt-staging -o wide

#------------------------------------------------------------------------
# CRÉATION DU CLUSTERISSUER LETSENCRYPT-PROD
#------------------------------------------------------------------------
# Création d'un émetteur de certificats pour l'environnement de production
# Utilisé pour obtenir des certificats de confiance valides

echo "Création du ClusterIssuer pour Let's Encrypt Production..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Vérification du statut du ClusterIssuer de production
kubectl get clusterissuer letsencrypt-prod -o wide

echo "Configuration du ClusterIssuer terminée"