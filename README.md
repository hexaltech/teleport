# 🛡️ Teleport Zero Trust Lab - Hexaltech

Ce dépôt contient la configuration et les scripts de déploiement de mon laboratoire de sécurité **Zero Trust**.

## 🏗️ Architecture
- **Bastion** : Debian 12 (Bookworm) sous Teleport v15.
- **Sécurité** : Certificats TLS Wildcard via **Cloudflare DNS-01** challenge.
- **Identité** : SSO intégré avec **GitHub**.
- **Cibles** : Instances AWS EC2, Active Directory local, et Imprimante réseau (IoT).

## 🛠️ Comment utiliser ce script ?
1. Cloner ce repo sur une VM Debian vierge.
2. Lancer `./install.sh`.
3. Configurer le token Cloudflare pour le certificat SSL :
   ```bash
   sudo systemctl edit teleport
   # Ajouter :
   # [Service]
   # Environment='CLOUDFLARE_API_TOKEN=votre_token'