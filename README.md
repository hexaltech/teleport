---

## 🚀 Fonctionnalités du Lab

* 🔐 **Authentification SSO**
  Connexion centralisée via **GitHub** (fin des clés SSH locales).

* ☸️ **Accès Kubernetes (K8s)**
  Intégration d’un cluster **K3s** via l’agent **Teleport (Helm)**, utilisant un **tunnel inversé sécurisé**.

* 🖥️ **Desktop Access (RDP)**
  Accès **Windows sans mot de passe (Passwordless)** via **Smart Card virtuelle** et intégration **Active Directory (LDAPS)**.

* 🌐 **HTTPS universel**
  Certificats **SSL wildcard** automatiques via le challenge **DNS-01 Cloudflare**.

* 🧩 **App Access**
  Exposition sécurisée d’applications web internes (imprimante, outils admin…) **sans IP publique**.

* 📋 **Audit & conformité**
  Enregistrement vidéo des sessions (**SSH, RDP**) et journalisation des requêtes `kubectl`.

---

## 📂 Structure du dépôt

```
.
├── install.sh               # Script d’installation du bastion Teleport (Debian 12)
├── CLOUDFLARE_GUIDE.md      # Certificat SSL wildcard & API Token Cloudflare
├── KUBERNETES_GUIDE.md      # Intégration Kubernetes via Helm (agent interne)
├── WINDOWS_AD_GUIDE.md      # Intégration Active Directory (LDAPS, GPO, Certificats)
└── config/                  # Modèles de configuration YAML Teleport
```

---

## ⚙️ Installation rapide

### 1️⃣ Déploiement du bastion Teleport

Le script `install.sh` :

* installe les dépendances,
* configure le dépôt APT officiel Teleport,
* prépare l’arborescence et les fichiers de configuration.

```bash
chmod +x install.sh
sudo ./install.sh
```

⚠️ **Important** — Le script est **interactif** et demande :

* le **nom de domaine** (ex. `teleport.hexaltech.fr`)
* l’**adresse email** utilisée pour la génération des certificats ACME

---

### 2️⃣ Sécurisation DNS (Cloudflare)

Pour activer le HTTPS sans avertissements de sécurité, suivez la procédure dédiée :

👉 **Voir le guide** : `CLOUDFLARE_GUIDE.md`

---

### 3️⃣ Connexion au cluster Kubernetes

Aucune modification lourde côté bastion.

L’intégration se fait exclusivement via l’**agent Helm** déployé sur le cluster cible (K3s, K8s managé ou on-prem) :

👉 **Voir le guide** : `KUBERNETES_GUIDE.md`

---

### 4️⃣ Intégration Active Directory (Windows)

Configuration :

* **Active Directory** (AD CS, LDAPS)
* **GPO Remote Desktop**
* **NLA désactivé** pour permettre l’authentification Smart Card virtuelle

👉 **Voir le guide** : `WINDOWS_AD_GUIDE.md`

---

## ⚠️ Personnalisation requise

Ce projet est **préconfiguré pour l’environnement Hexaltech**.

Avant toute utilisation en production, adaptez le fichier :

```
/etc/teleport.yaml
```

### 🔧 Points à modifier

#### 🆔 Identity Service

Remplacez le FQDN par votre domaine :

```yaml
teleport:
  nodename: teleport.hexaltech.fr
```

---

#### 🌐 App Service

Ajustez les IP / URLs de vos applications internes :

```yaml
app_service:
  apps:
    - name: "mon-app"
      uri: "http://192.168.1.50"  # IP locale de l'application
```

---

#### 🖥️ Windows Desktop Service

Mettez à jour les informations de votre domaine Active Directory :

```yaml
windows_desktop_service:
  ldap:
    addr: "192.168.20.150:636"   # IP du contrôleur de domaine
    domain: "hexaltech.lan"      # Domaine AD
    sid: "S-1-5-21-..."          # SID du compte svc-teleport
```

---

#### 🔐 RBAC & Accès utilisateurs

Adaptez les rôles via :

```bash
tctl edit role <role-name>
```

Objectifs :

* mapper les **équipes GitHub** vers :

  * les droits Kubernetes (`system:masters` ou restreints)
  * les logins Windows (Administrateur, User, etc.)

---

## 👨‍💻 Défis techniques relevés

* 🧠 **Architecture Agentless vs Agent**
  Migration d’un accès Kubernetes direct (`kubeconfig`) vers une architecture **agent Helm**, plus robuste et résiliente réseau.

* 🌐 **Routage inter-VLAN**
  Communication sécurisée entre le bastion (DMZ) et des ressources critiques (**K3s, IoT, AD**) situées dans des VLANs isolés.

* 🖥️ **RDP & certificats**
  Mise en place du **LDAPS**, gestion des **GPO RemoteFX** et suppression de **NLA** pour permettre le **Passwordless via Smart Card virtuelle**.

* 🔄 **Automatisation ACME**
  Gestion complète du cycle de vie des certificats SSL via l’**API Cloudflare**, sans renouvellement manuel.

---
