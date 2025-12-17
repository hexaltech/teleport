```markdown
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

```

> **⚠️ Important** : Le script est interactif. Il demande :
> * Le **nom de domaine** (ex. `teleport.hexaltech.fr`)
> * L’**adresse email** utilisée pour la génération des certificats ACME
> 
> 

### 2. Sécurisation DNS (Cloudflare)

Pour activer le HTTPS sans avertissements de sécurité, suivez la procédure dédiée :
👉 **[Voir le guide Cloudflare](https://www.google.com/search?q=CLOUDFLARE_GUIDE.md)**

### 3. Connexion au cluster Kubernetes

Aucune modification lourde côté bastion. L’intégration se fait exclusivement via l’agent Helm déployé sur le cluster cible :
👉 **[Voir le guide Kubernetes](https://www.google.com/search?q=KUBERNETES_GUIDE.md)**

### 4. Intégration Active Directory (Windows)

Configuration de l'AD (AD CS, GPO RemoteFX, NLA désactivé) et du bastion pour la découverte LDAP :
👉 **[Voir le guide Windows & AD](https://www.google.com/search?q=WINDOWS_AD_GUIDE.md)**

## ⚠️ Personnalisation

Ce projet est préconfiguré pour l’environnement **Hexaltech**. Avant toute utilisation, adaptez le fichier `/etc/teleport.yaml`.

### Points à modifier

1. **Identity** : Remplacez `teleport.hexaltech.fr` par votre FQDN.
2. **App Service** : Ajustez les IP cibles de vos applications internes.
```yaml
app_service:
  apps:
    - name: "mon-app"
      uri: "[http://192.168.1.50](http://192.168.1.50)" # IP locale de l'application

```


3. **Windows Service** : Mettez à jour les infos de votre domaine AD.
```yaml
windows_desktop_service:
  ldap:
    addr: "192.168.20.150:636"      # IP de votre AD
    domain: "hexaltech.lan"         # Votre domaine
    sid: "S-1-5-21-..."             # SID du compte svc-teleport

```


4. **RBAC** : Adaptez les rôles utilisateurs via `tctl edit role` pour mapper vos équipes GitHub aux droits Kubernetes (`system:masters`) et aux logins Windows (`Administrateur`).

## 👨‍💻 Défis techniques relevés

* **Architecture Agentless vs Agent** : Passage d’un accès Kubernetes direct (kubeconfig) à une architecture **agent Helm**, plus robuste et résiliente réseau.
* **Routage inter-VLAN** : Communication sécurisée entre le bastion (DMZ) et des ressources critiques (K3s, IoT, AD) situées dans des VLANs isolés.
* **Protocole RDP & Certificats** : Mise en place du **LDAPS**, gestion des **GPO** pour RemoteFX et suppression de l'authentification NLA pour permettre le "Passwordless" via Smart Card virtuelle.
* **Automatisation ACME** : Gestion complète du cycle de vie des certificats SSL via l’API Cloudflare, sans renouvellement manuel.

---
```

```

