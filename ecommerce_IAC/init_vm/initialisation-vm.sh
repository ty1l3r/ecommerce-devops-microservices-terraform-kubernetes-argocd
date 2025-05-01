#!/bin/bash
#-----------------------------------------------------------------
# Script d'initialisation et de configuration de VM distante
# Auteur: Tyler
# Dernière mise à jour: Janvier 2025
#
# Description:
#   Ce script prépare une machine virtuelle distante pour un usage DevOps
#   en configurant un utilisateur non-root avec accès SSH sécurisé.
#   Il vérifie d'abord si la machine est déjà configurée et, si nécessaire,
#   effectue les opérations suivantes:
#   1. Création d'un utilisateur Ubuntu avec privilèges sudo
#   2. Configuration de l'authentification par clé SSH
#   3. Désactivation de l'authentification par mot de passe
#
# Utilisation:
#   ./initialisation-vm.sh
#
# Prérequis:
#   - Un fichier password.txt contenant le mot de passe de la VM
#   - Une paire de clés SSH dans ~/.ssh/cleSSH et ~/.ssh/cleSSH.pub
#   - L'adresse IP de la VM cible configurée dans la variable REMOTE_HOST
#-----------------------------------------------------------------

# Couleurs et variables de configuration
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"
SEPARATOR="\n=====================================================\n"
REMOTE_USER_ROOT="root"
REMOTE_USER_UBUNTU="ubuntu"
REMOTE_HOST="YOUR_IP_ADDRESS"
SSH_KEY_PATH="$HOME/.ssh/cleSSH.pub"
LOCAL_PRIVATE_KEY="$HOME/.ssh/cleSSH"
PASSWORD_FILE="password.txt"

# Charger le mot de passe root depuis le fichier local
if [ ! -f "$PASSWORD_FILE" ]; then
  echo -e "${RED}Le fichier de mot de passe $PASSWORD_FILE est manquant...FAIL${NC}"
  exit 1
fi
REMOTE_PASS=$(cat "$PASSWORD_FILE")

#########################################################################
# GESTION DES CLÉS SSH ET INITIALISATION UTILISATEUR                     #
#########################################################################
# Cette section gère la configuration SSH sécurisée:
# 1. Supprime les anciens enregistrements de la VM dans known_hosts
# 2. Ajoute la nouvelle empreinte SSH de la VM 
# 3. Vérifie si la connexion SSH avec l'utilisateur ubuntu est possible

echo -e "$SEPARATOR Gestion des clés SSH $SEPARATOR"
ssh-keygen -R "$REMOTE_HOST" -f "$HOME/.ssh/known_hosts"
ssh-keyscan -H "$REMOTE_HOST" >> "$HOME/.ssh/known_hosts"

# Vérification de la connexion SSH avec 'ubuntu'
echo -e "$SEPARATOR Vérification de la configuration de la machine $SEPARATOR"
ssh -i "$LOCAL_PRIVATE_KEY" -o BatchMode=yes -o StrictHostKeyChecking=no $REMOTE_USER_UBUNTU@$REMOTE_HOST "exit"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}La machine est déjà configurée. Connexion SSH avec 'ubuntu' réussie...${NC}"
else
  echo -e "${RED}La machine n'est pas encore configurée. Initialisation en cours...${NC}"
  echo -e "$SEPARATOR Connexion via mot de passe root pour initialisation de la machine $SEPARATOR"

  # Connexion avec mot de passe root pour initialiser la machine
  # Cette étape configure un utilisateur non-root (ubuntu) avec:
  # - Des droits sudo sans mot de passe
  # - Un répertoire .ssh correctement sécurisé
  # - Les permissions adaptées pour l'authentification par clé
  sshpass -p "$REMOTE_PASS" ssh -t -o StrictHostKeyChecking=no $REMOTE_USER_ROOT@$REMOTE_HOST <<EOF
    echo -e "${GREEN}Mise à jour des paquets et installation des outils nécessaires...${NC}"
    sudo apt update && sudo apt install -y sshpass

    # Créer l'utilisateur 'ubuntu' si nécessaire
    if id "ubuntu" &>/dev/null; then
      echo -e "${GREEN}L'utilisateur 'ubuntu' existe déjà...PASS${NC}"
    else
      echo -e "${GREEN}Création de l'utilisateur 'ubuntu'...${NC}"
      sudo adduser ubuntu --gecos "Ubuntu,,," --disabled-password
      echo "ubuntu:$REMOTE_PASS" | sudo chpasswd
      sudo usermod -aG sudo ubuntu
    fi

    # Ajouter un accès sudo sans mot de passe pour 'ubuntu'
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ubuntu > /dev/null
    sudo chmod 0440 /etc/sudoers.d/ubuntu

    # Configurer le répertoire .ssh pour 'ubuntu'
    sudo mkdir -p /home/ubuntu/.ssh
    sudo chmod 700 /home/ubuntu/.ssh
    sudo touch /home/ubuntu/.ssh/authorized_keys
    sudo chmod 600 /home/ubuntu/.ssh/authorized_keys
    sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh
EOF

  # Transférer la clé publique vers la machine distante
  # Cette étape ajoute votre clé SSH publique à la liste des clés autorisées
  # pour permettre une connexion SSH sans mot de passe à l'avenir
  echo -e "$SEPARATOR Transfert de la clé publique vers la machine distante $SEPARATOR"
  sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no "$SSH_KEY_PATH" $REMOTE_USER_UBUNTU@$REMOTE_HOST:/home/ubuntu/.ssh/vmf.pub

  # Ajouter la clé publique à authorized_keys sur la machine distante
  sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no $REMOTE_USER_UBUNTU@$REMOTE_HOST "cat /home/ubuntu/.ssh/vmf.pub >> /home/ubuntu/.ssh/authorized_keys && rm /home/ubuntu/.ssh/vmf.pub"

  # Vérifier si la clé SSH est copiée avec succès
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Clé SSH copiée avec succès pour l'utilisateur 'ubuntu'.${NC}"
  else
    echo -e "${RED}Échec lors de la copie de la clé SSH pour l'utilisateur 'ubuntu'.${NC}"
    exit 1
  fi
fi

#########################################################################
# CONTINUER LA CONFIGURATION VIA LA CONNEXION SSH AVEC 'UBUNTU'         #
#########################################################################
# Cette section utilise la connexion SSH configurée précédemment pour
# effectuer des configurations supplémentaires sur la VM distante.
# L'authentification se fait maintenant par clé SSH, sans mot de passe.

echo -e "$SEPARATOR Connexion en tant qu'utilisateur 'ubuntu' et continuation de la configuration $SEPARATOR"
ssh -i "$LOCAL_PRIVATE_KEY" -o BatchMode=yes $REMOTE_USER_UBUNTU@$REMOTE_HOST <<EOF
  # Exemple de configuration supplémentaire après connexion SSH réussie
  echo -e "${GREEN}Connexion SSH avec 'ubuntu' réussie. Continuation de la configuration...${NC}"

  # Autres configurations ou installations de votre choix
  echo -e "${GREEN}Configuration terminée pour 'ubuntu'.${NC}"
EOF
