#!/bin/bash
#-----------------------------------------------------------------
# Script de configuration du pare-feu pour environnement Kubernetes
# Auteur: Tyler
# Dernière mise à jour: Janvier 2025
#
# Description:
#   Ce script configure le pare-feu UFW sur une VM distante pour
#   permettre le trafic nécessaire à un cluster Kubernetes (K3s).
#   Il ouvre les ports requis pour l'API Kubernetes, les communications
#   inter-nœuds, et les services exposés (HTTP/HTTPS, NodePorts).
#
# Utilisation:
#   ./firewall-vm.sh
#
# Prérequis:
#   - L'adresse IP de la VM cible configurée dans la variable REMOTE_HOST
#   - sshpass installé sur la machine locale
#-----------------------------------------------------------------

# Couleurs pour le feedback visuel
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # No Color

# Délimiteur visuel
SEPARATOR="\n=====================================================\n"

# Variables pour la machine distante
REMOTE_USER="ubuntu"
REMOTE_HOST="YOUR_IP_ADDRESS"
PASSWORD_FILE="password.txt"
LOCAL_KUBECONFIG_PATH="$HOME/.kube/config"
REMOTE_K3S_CTL_PATH="/etc/rancher/k3s/k3s.yaml"

# Charger le mot de passe utilisateur ubuntu à partir du fichier
if [ ! -f "$PASSWORD_FILE" ]; then
  echo -e "${RED}Le fichier de mot de passe $PASSWORD_FILE est manquant...FAIL${NC}"
  exit 1
fi

REMOTE_PASS=$(cat "$PASSWORD_FILE")

echo -e "$SEPARATOR Début de la configuration du pare-feu sur la VM distante $SEPARATOR"

# Connexion SSH et exécution du script de configuration du pare-feu
sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << 'EOF'
# Définir les couleurs pour le feedback visuel
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # No Color

# Délimiteur visuel
SEPARATOR="\n=====================================================\n"

echo -e "$SEPARATOR Début de la configuration du pare-feu sur la VM $SEPARATOR"

#########################################################################
#               DÉFINITION DES PORTS À AUTORISER                        #
#########################################################################
# Liste des ports nécessaires pour le fonctionnement de Kubernetes
# et des services associés (API, communication, monitoring, applications)

ports_to_allow=(
  "22/tcp"      # SSH - Accès sécurisé à la machine
  "6443/tcp"    # API Kubernetes kubectl - Communication avec le cluster
  "8472/udp"    # Communication réseau entre les nœuds (flannel)
  "10250/tcp"   # Kubelet - Agent sur chaque nœud
  "10251/tcp"   # Kube-scheduler - Planification des pods
  "10252/tcp"   # Kube-controller-manager - Gestion des contrôleurs
  "80/tcp"      # HTTP - Trafic web standard
  "443/tcp"     # HTTPS - Trafic web sécurisé
  "5672"        # RabbitMQ - Communication entre services
  "15672"       # Interface de gestion RabbitMQ
  "31854"       # NodePort HTTP - Service exposé via NodePort
  "30763"       # NodePort HTTPS - Service exposé via NodePort
  "9090"        # Prometheus - Monitoring
  "8081"        # MongoDB Express pour Products - Interface d'admin
  "8082"        # MongoDB Express pour Customers - Interface d'admin
)

#########################################################################
#        CONFIGURATION POUR IGNORER L'IPV6 SI NÉCESSAIRE                #
#########################################################################
# Désactivation d'IPv6 dans UFW pour éviter les conflits de configuration
# et simplifier la gestion des règles de pare-feu

echo -e "$SEPARATOR Désactivation de l'IPv6 dans UFW si non nécessaire $SEPARATOR"
sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
sudo systemctl restart ufw
sleep 2  # Pause pour stabiliser UFW après le redémarrage

#########################################################################
#        RÉINITIALISATION DU PARE-FEU UFW EN CAS DE CONFLIT             #
#########################################################################
# Réinitialisation complète de UFW pour partir d'un état propre
# et éviter toute configuration résiduelle problématique

echo -e "$SEPARATOR Réinitialisation de UFW $SEPARATOR"
sudo ufw --force reset
sleep 2  # Pause pour stabiliser UFW après la réinitialisation

#########################################################################
#      VÉRIFICATION ET ACTIVATION DU PARE-FEU (SI NÉCESSAIRE)           #
#########################################################################
# Vérification du statut actuel de UFW et activation si nécessaire
# avec confirmation automatique pour éviter les interventions manuelles

sudo ufw status | grep -q "Status: active"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Le pare-feu est déjà activé.${NC}"
else
  echo -e "${GREEN}Activation du pare-feu UFW...${NC}"
  echo "y" | sudo ufw --force enable
  sleep 2
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Pare-feu activé avec succès...PASS${NC}"
  else
    echo -e "${RED}Échec lors de l'activation du pare-feu...FAIL${NC}"
    sudo ufw status verbose
    exit 1
  fi
fi

#########################################################################
#          AUTORISER LES PORTS DÉFINIS DANS LE TABLEAU                  #
#########################################################################
# Ouverture des ports nécessaires définis dans le tableau ports_to_allow
# Vérification pour chaque port s'il est déjà ouvert avant de le configurer

for port in "${ports_to_allow[@]}"; do
  sudo ufw status | grep -q "$port"
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Le port $port est déjà ouvert.${NC}"
  else
    echo -e "$SEPARATOR Ouverture du port $port $SEPARATOR"
    sudo ufw allow "$port"
    sleep 1  # Pause pour éviter les conflits de verrouillage
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}Port $port ouvert avec succès...PASS${NC}"
    else
      echo -e "${RED}Échec lors de l'ouverture du port $port...FAIL${NC}"
      exit 1
    fi
  fi
done

#########################################################################
#            APPLIQUER LES RÈGLES PAR DÉFAUT DU PARE-FEU                #
#########################################################################
# Configuration des règles par défaut pour refuser tout trafic entrant
# et permettre tout trafic sortant

echo -e "$SEPARATOR Application des règles par défaut : refuser tout trafic entrant, permettre tout trafic sortant $SEPARATOR"
sudo ufw default deny incoming
sleep 1
if [ $? -ne 0 ]; then
  echo -e "${RED}Échec lors de la configuration des règles par défaut du trafic entrant...FAIL${NC}"
  exit 1
fi

sudo ufw default allow outgoing
sleep 1
if [ $? -ne 0 ]; then
  echo -e "${RED}Échec lors de la configuration des règles par défaut du trafic sortant...FAIL${NC}"
  exit 1
fi

#########################################################################
#                 DÉSACTIVER LA JOURNALISATION DU PARE-FEU             #
#########################################################################
# Désactivation de la journalisation UFW pour éviter la saturation des logs
# et améliorer les performances

echo -e "$SEPARATOR Désactivation des règles de journalisation $SEPARATOR"
sudo ufw logging off
if [ $? -ne 0 ]; then
  echo -e "${RED}Échec lors de la désactivation des règles de journalisation...FAIL${NC}"
fi

#########################################################################
#                 VÉRIFICATION FINALE DU STATUT DU PARE-FEU             #
#########################################################################
# Vérification finale pour s'assurer que le pare-feu est activé et fonctionnel

echo -e "$SEPARATOR Vérification finale du pare-feu $SEPARATOR"
if sudo ufw status | grep -q "Status: active"; then
    echo -e "${GREEN}Pare-feu activé et fonctionnel...PASS${NC}"
else
    echo -e "${RED}Le pare-feu n'est pas activé...FAIL${NC}"
    exit 1
fi

echo -e "$SEPARATOR Pare-feu configuré avec succès! $SEPARATOR"
EOF

# Vérification du succès de l'exécution distante
if [ $? -ne 0 ]; then
  echo -e "${RED}L'exécution du script sur la machine distante a échoué...FAIL${NC}"
  exit 1
else
  echo -e "${GREEN}Script exécuté avec succès sur la machine distante...PASS${NC}"
fi
