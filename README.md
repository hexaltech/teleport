## 🛠️ Installation et Personnalisation

> [!IMPORTANT]
> Ce projet est configuré pour l'infrastructure **Hexaltech**. Avant de lancer l'installation, vous devez adapter les fichiers à votre propre environnement.

### 1. Adaptation du script d'installation
Avant d'exécuter `install.sh`, assurez-vous de modifier les variables suivantes dans le script ou dans le fichier `/etc/teleport.yaml` généré :

- **`cluster_name`** : Remplacez `teleport.hexaltech.fr` par votre propre nom de domaine.
- **`public_addr`** : Doit correspondre à votre URL d'accès externe.
- **`email`** : Remplacez `contact@hexaltech.fr` par votre adresse email pour recevoir les alertes de renouvellement Let's Encrypt (ACME).
- **`nodename`** : Donnez un nom unique à votre bastion.

### 2. Configuration Cloudflare
Si vous utilisez Cloudflare pour le certificat SSL Wildcard, n'oubliez pas d'injecter votre propre Token API :
```bash
sudo systemctl edit teleport
# Ajoutez vos informations :
[Service]
Environment='CLOUDFLARE_API_TOKEN=VOTRE_TOKEN_PERSONNEL'
