# 🏰 Guide d'Implémentation Teleport Desktop Access (SSO GitHub & AD)

Ce document détaille l'installation complète de l'accès sécurisé aux serveurs et PC Windows via **Teleport**, en utilisant **GitHub** pour l'authentification des utilisateurs (SSO) et le protocole LDAPS pour la liaison technique.

## 🏗️ Architecture

* **Cluster Teleport** : `https://teleport.hexaltech.fr`
* **Bastion Linux** : `192.168.50.250` (Services : Proxy, Auth, Windows Desktop, Discovery, Apps)
* **Active Directory (AD)** : `192.168.50.150` (Windows Server 2025)
* **Domaine** : `hexaltech.lan`
* **Clients** : Découverte automatique des PC joints au domaine.
* **Imprimantes** : Accès sécurisé via le module Applications.

---

## 🐙 Phase 1 : Configuration GitHub (SSO)

### 1. Prérequis GitHub
1.  Créer une **Organisation** sur GitHub (ex: `hexaltech-organization`).
2.  Créer une **Équipe** dans cette organisation (ex: `admins`).
3.  Ajouter les utilisateurs dans cette équipe.

### 2. Création de l'application OAuth
Dans **GitHub > Settings > Developer settings > OAuth Apps** :
* **Homepage URL** : `https://teleport.hexaltech.fr`
* **Callback URL** : `https://teleport.hexaltech.fr/v1/webapi/github/callback`
* **⚠️ Important :** Dans "Authorized OAuth Apps", cliquer sur **Grant** à côté de l'organisation pour autoriser l'accès.

### 3. Configuration du Connecteur (Sur le Bastion)
Fichier `/etc/teleport/github-connector.yaml` :

```yaml
kind: github
version: v3
metadata:
  name: github
spec:
  client_id: "VOTRE_CLIENT_ID"
  client_secret: "VOTRE_CLIENT_SECRET"
  display: "GitHub"
  redirect_url: "[https://teleport.hexaltech.fr/v1/webapi/github/callback](https://teleport.hexaltech.fr/v1/webapi/github/callback)"

  teams_to_roles:
    - organization: "hexaltech-organization"
      team: "admins"
      roles: ["access", "editor", "windows-admin"]

```

Commande d'application : `sudo tctl create -f github-connector.yaml --force`

---

## 🖥️ Phase 2 : Préparation Windows (AD & Clients)

### 1. Configuration Active Directory (Serveur)

* **Certificat :** Installer le rôle **AD CS**. Importer le certificat Teleport (`user-ca.cer`) dans les magasins **Enterprise Root CA** et **NTAuthCA**.
* **Compte de service :** Créer un utilisateur standard `svc-teleport` et récupérer son **SID** (`Get-AdUser svc-teleport`).
* **GPO "Teleport Access Policy"** (A appliquer sur tout le domaine) :
* **Service "Carte à puce"** : Définir sur **Automatique**.
* **Sécurité RDP** : **Désactiver le NLA** (Network Level Authentication) -> *Crucial sinon Teleport est rejeté.*
* **RemoteFX** : Activé (recommandé pour les performances).



### 2. Préparation des PC Clients (⚠️ CRITIQUE)

Par défaut, les PC Clients (Windows 10/11) bloquent le RDP venant d'une autre IP (le Bastion) même si le service est actif.

**Action obligatoire sur chaque nouveau PC :**
Ouvrir PowerShell en Administrateur et lancer cette commande pour ouvrir le port 3389 :

```powershell
New-NetFirewallRule -DisplayName "Teleport RDP Access" -Direction Inbound -LocalPort 3389 -Protocol TCP -Action Allow -Profile Any

```

---

## 🐧 Phase 3 : Configuration du Bastion (Linux)

Fichier de configuration `/etc/teleport.yaml` complet et validé.

```yaml
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

# 1. Service Desktop (Connexion RDP/LDAP)
windows_desktop_service:
  enabled: "yes"
  listen_addr: "0.0.0.0:3028"
  public_addr: "192.168.50.250:3028"
  ldap:
    addr: "192.168.50.150:636"
    domain: "hexaltech.lan"
    username: "svc-teleport"
    sid: "S-1-5-21-438133749-1811766057-640718-1106" # Votre SID
    insecure_skip_verify: true

# 2. Service Découverte (Scan automatique du réseau)
discovery_service:
  enabled: "yes"
  discovery_configs:
    - service_type: windows_desktop
      base_dn: "DC=hexaltech,DC=lan"
      filters:
        - "(objectClass=computer)"
      services:
        - windows_desktop

# 3. Service Applications (Accès Web Imprimantes/Switchs)
app_service:
  enabled: "yes"
  apps:
    - name: "imprimante-laser"
      uri: "[http://192.168.1.200](http://192.168.1.200)"
      insecure_skip_verify: true
      labels:
        type: "printer"

```

Appliquer les changements : `sudo systemctl restart teleport`

---

## 👤 Phase 4 : Rôle Utilisateur

Ce rôle permet aux utilisateurs de l'équipe GitHub "admins" de se connecter en tant qu'administrateur local ou domaine.

Fichier `role-windows-admin.yaml` :

```yaml
kind: role
version: v5
metadata:
  name: windows-admin
spec:
  allow:
    windows_desktop_labels:
      "*": "*"
    windows_desktop_logins: ["Administrateur", "administrateur", "Administrator"]

```

Application : `sudo tctl create -f role-windows-admin.yaml`

---

## 🛠️ Dépannage et Erreurs Courantes

### 1. Erreur "Ressources système insuffisantes" (Carte à puce)

**Symptôme :** Lors de la connexion, Windows affiche l'erreur *"Ressources système insuffisantes pour terminer le service demandé"*.
**Cause :** Conflit entre le driver de carte à puce virtuelle Teleport et le service de propagation de certificat Windows.

**Solution :**
Sur le PC Windows concerné, exécuter ces commandes en PowerShell (Admin) :

```powershell
# Arrêter et désactiver le service "Propagation du certificat"
Stop-Service -Name CertPropSvc -Force
Set-Service -Name CertPropSvc -StartupType Disabled

# Redémarrer le PC
Restart-Computer -Force

```

### 2. Erreur "Connection Timed Out" / "Disconnected"

**Symptôme :** Teleport voit le PC dans la liste, mais impossible de se connecter.
**Causes probables :**

1. **Pare-feu Windows :** Le PC bloque le port 3389. -> Voir **Phase 2, étape 2** (commande `New-NetFirewallRule`).
2. **DNS Bastion :** Le bastion n'arrive pas à résoudre le nom du PC (`ping NOM-PC`). -> Ajouter le PC dans `/etc/hosts` sur le Linux.

### 3. Liste des PC vide dans Teleport

* Le service de découverte met 5 à 10 minutes pour scanner les nouveaux PC.
* Pour forcer un scan : `sudo systemctl restart teleport` sur le bastion.

```

```
