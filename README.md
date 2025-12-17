# 🛡️ Teleport Zero Trust Lab - Hexaltech

Ce dépôt contient la configuration et les scripts de déploiement d'un laboratoire de sécurité **Zero Trust** utilisant **Teleport**. Ce projet démontre comment centraliser l'accès à une infrastructure hybride (On-premise & Cloud) tout en supprimant la dépendance aux VPN et aux mots de passe statiques.

## 🚀 Fonctionnalités du Lab

* **Authentification SSO (GitHub)** : Connexion sécurisée déléguée à GitHub avec gestion des rôles par équipe.
* **Certificat Wildcard Automatique** : Utilisation du protocole ACME avec le challenge DNS-01 de **Cloudflare** pour sécuriser tous les sous-domaines.
* **Accès aux Applications (App Access)** : Publication sécurisée d'une interface web d'imprimante locale via un tunnel TLS.
* **Infrastructure Hybride** : Gestion centralisée d'instances **AWS EC2** (Linux) et d'un environnement **Active Directory** local (Hyper-V).
* **Audit & Compliance** : Enregistrement intégral des sessions SSH/RDP et journalisation des requêtes SQL/HTTP.

## 🛠️ Structure du Projet

* `install.sh` : Script d'automatisation pour installer Teleport sur une VM Debian/Ubuntu vierge.
* `CLOUDFLARE_GUIDE.md` : Procédure détaillée pour la mise en place du certificat SSL Wildcard.
* `/config` : Modèles de fichiers `teleport.yaml` (Template).

---

## ⚙️ Installation Rapide

### 1. Prérequis

Une VM Debian 12 (Bookworm) avec une adresse IP publique ou un accès internet configuré (Routage VLAN opérationnel pour le lab local).

### 2. Déploiement du Bastion

Récupérez le script et lancez l'installation :

```bash
chmod +x install.sh
sudo ./install.sh

```

> [!IMPORTANT]
> Le script vous demandera de saisir votre **Nom de domaine** (ex: `teleport.hexaltech.fr`) et votre **Email**. Ces informations sont cruciales pour la génération des certificats SSL.

### 3. Configuration de la Sécurité (DNS)

Pour activer le cadenas vert sur toutes vos applications, suivez le [Guide Cloudflare](https://www.google.com/search?q=./CLOUDFLARE_GUIDE.md) pour injecter votre Token API de manière sécurisée.

---

## ⚠️ Personnalisation (Best Practices)

Pour adapter ce lab à votre propre réseau, vous devez modifier les sections suivantes dans `/etc/teleport.yaml` :

1. **Section `auth_service**` : Changez le `cluster_name` pour qu'il corresponde à votre domaine DNS.
2. **Section `app_service**` : Modifiez l'URI de l'imprimante ou des outils internes (ex: `http://192.168.x.x`).
3. **Section `ssh_service**` : Activez ou désactivez l'accès SSH selon vos besoins de sécurité.

---

## 📝 Défis Techniques Relevés

* **Routage Inter-VLAN** : Configuration du bastion pour communiquer avec des équipements sur des segments réseau isolés (VLAN IoT pour l'imprimante).
* **Persistance HSTS** : Résolution des conflits de certificats navigateurs lors de la mise en place du Wildcard DNS.
* **Identity Mapping** : Corrélation entre les identités GitHub et les rôles RBAC (Role-Based Access Control) de Teleport.
