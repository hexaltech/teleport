#!/bin/bash
# Script de déploiement automatique Teleport - Hexaltech Lab

set -e # Arrête le script en cas d'erreur

echo "--- Mise à jour et installation des prérequis ---"
sudo apt update && sudo apt install -y curl wget apt-transport-https gnupg sudo

echo "--- Configuration du dépôt Teleport ---"
sudo curl https://apt.releases.teleport.dev/gpg -o /usr/share/keyrings/teleport-archive-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/teleport-archive-keyring.asc] https://apt.releases.teleport.dev/debian bookworm stable/v15" | sudo tee /etc/apt/sources.list.d/teleport.list
sudo apt update

echo "--- Installation de Teleport ---"
sudo apt install -y teleport

echo "--- Nettoyage et configuration initiale ---"
sudo systemctl stop teleport || true
sudo rm -rf /var/lib/teleport/*
sudo rm -f /etc/teleport.yaml

# Génération du fichier de configuration
sudo tee /etc/teleport.yaml > /dev/null <<EOF
version: v3
teleport:
  nodename: TELEPORT-BASTION
  data_dir: /var/lib/teleport
  log:
    output: stderr
    severity: INFO
auth_service:
  enabled: "yes"
  cluster_name: "teleport.hexaltech.fr"
  listen_addr: 0.0.0.0:3025
  proxy_listener_mode: multiplex
ssh_service:
  enabled: "yes"
proxy_service:
  enabled: "yes"
  web_listen_addr: "0.0.0.0:443"
  public_addr: "teleport.hexaltech.fr:443"
  acme:
    enabled: "yes"
    email: "contact@hexaltech.fr"
EOF

echo "--- Activation du service ---"
sudo systemctl enable teleport
sudo systemctl start teleport

echo "Installation terminée. N'oubliez pas de configurer le TOKEN Cloudflare avec 'systemctl edit teleport'."