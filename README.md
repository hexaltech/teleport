# 🛡️ Teleport Zero Trust Lab — Hexaltech

Ce dépôt contient l'Infrastructure as Code (IaC) et la documentation technique d’un laboratoire de sécurité **Zero Trust** basé sur **Teleport**.

Le projet démontre comment sécuriser et unifier l’accès à une infrastructure hybride (**Linux, Kubernetes, IoT, Windows / Active Directory**) **sans VPN**, **sans ports exposés**, tout en garantissant une **traçabilité complète** (audit logs, replay de sessions).

## 🚀 Fonctionnalités du Lab

* **Authentification SSO** : Connexion centralisée via **GitHub** (fin des clés SSH locales).
* **Accès Kubernetes (K8s)** : Intégration d’un cluster **K3s** via l’agent Teleport (Helm), utilisant un tunnel inversé sécurisé.
* **Desktop Access (RDP)** : Accès **Windows sans mot de passe** (Passwordless) via simulation de Smart Card virtuelle et intégration **Active Directory (LDAPS)**.
* **HTTPS universel** : Certificats **SSL wildcard** automatiques via le challenge DNS-01 de **Cloudflare**.
* **App Access** : Exposition sécurisée d’applications web internes (imprimante, outils admin…) sans IP publique.
* **Audit & conformité** : Enregistrement vidéo des sessions (SSH, RDP) et journalisation des requêtes `kubectl`.

## 📂 Structure du dépôt

* `install.sh` : Script Bash d’automatisation pour déployer le bastion Teleport sur Debian 12.
* `CLOUDFLARE_GUIDE.md` : Procédure de mise en place du certificat SSL wildcard et gestion du token API.
* `KUBERNETES_GUIDE.md` : Guide d’intégration d’un cluster Kubernetes via Helm (agent interne).
* `WINDOWS_AD_GUIDE.md` : Guide complet pour l'intégration Active Directory (LDAPS, GPO, Certificats).
* `config/` : Modèles de fichiers de configuration YAML.

## ⚙️ Installation rapide

### 1. Déploiement du bastion
Le script `install.sh` installe les dépendances, configure le dépôt APT officiel de Teleport et prépare l’arborescence de configuration.

```bash
chmod +x install.sh
sudo ./install.sh
