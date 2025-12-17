# 🏰 Guide d'Implémentation Teleport Desktop Access (Hexaltech)

Ce document détaille l'installation complète de l'accès sécurisé aux serveurs Windows (Active Directory) via **Teleport**, en utilisant l'authentification par certificat (Smart Card virtuelle) et le protocole LDAPS.

## 🏗️ Architecture

* **Cluster Teleport** : `https://teleport.hexaltech.fr`
* **Bastion Linux** : `192.168.20.250` (Services : Proxy, Auth, Windows Desktop)
* **Active Directory (AD)** : `192.168.20.150` (Windows Server 2025)
* **Domaine** : `hexaltech.lan`

---

## 🖥️ Phase 1 : Préparation de l'Active Directory (Windows)

### Étape 1 : Activation du LDAPS (Port 636)

Sur une installation Windows Server fraîche, le port sécurisé 636 est fermé par défaut.

1. Ouvrir le **Gestionnaire de serveur**.
2. Ajouter le rôle **Services de certificats Active Directory (AD CS)**.
3. Configurer le rôle en tant qu'**Autorité de certification Racine d'entreprise** (Enterprise Root CA).
4. Une fois terminé, vérifier que le port 636 est ouvert via PowerShell :
```powershell
Test-NetConnection -Port 636 -ComputerName localhost

```



### Étape 2 : Importation du Certificat Teleport

L'AD doit faire confiance aux certificats utilisateurs émis par Teleport.

1. Télécharger le certificat CA de Teleport depuis le serveur AD :
* URL : `https://teleport.hexaltech.fr/webapi/auth/export?type=windows`


2. Renommer le fichier téléchargé en **`user-ca.cer`**.
3. Ouvrir PowerShell en **Administrateur** et exécuter :
```powershell
certutil -dspublish -f user-ca.cer RootCA
certutil -dspublish -f user-ca.cer NTAuthCA
gpupdate /force

```



### Étape 3 : Création du Compte de Service

Teleport utilise ce compte pour scanner le réseau via LDAP.

1. Créer un utilisateur standard nommé **`svc-teleport`**.
2. Récupérer son **SID** (nécessaire pour la config Linux) :
```powershell
Get-AdUser -Identity "svc-teleport" | Select SID
# SID Hexaltech : S-1-5-21-438133749-1811766057-640718-1106

```



### Étape 4 : Configuration de la GPO (Stratégie de Groupe)

Créer une GPO nommée **"Teleport Access Policy"** et la lier à la racine du domaine. Modifier les paramètres suivants :

#### A. Activation Smart Card

* **Chemin** : `Configuration ordinateur > Stratégies > Paramètres Windows > Paramètres de sécurité > Services système`
* **Service "Carte à puce"** : Définir sur **Automatique**.

#### B. Sécurité RDP

* **Chemin** : `Configuration ordinateur > Modèles d'administration > Composants Windows > Services Bureau à distance > Hôte de session > Sécurité`
* **Exiger l'authentification réseau (NLA)** : **Désactivé** (Indispensable).
* **Toujours demander le mot de passe** : **Désactivé**.

#### C. Affichage et Codec (RemoteFX)

* **Chemin** : `... > Hôte de session > Environnement de session à distance`
* **Configurer RemoteFX** : **Activé**.
* **Activer l'encodage RemoteFX** : **Activé**.
* **Définir l'algorithme de compression RDP** : **Activé** -> Choisir **"Optimisé pour utiliser moins de mémoire réseau"**.

> 💡 **Important** : Appliquer les changements sur l'AD avec la commande `gpupdate /force`.

---

## 🐧 Phase 2 : Configuration du Bastion (Linux)

Modifier le fichier de configuration `/etc/teleport.yaml`.

### Configuration du Service Windows

Ajouter ou modifier la section `windows_desktop_service` avec les paramètres suivants :

```yaml
windows_desktop_service:
  enabled: "yes"
  # Port d'écoute local du service
  listen_addr: "0.0.0.0:3028"
  # Adresse IP publique/LAN du bastion (Indispensable pour le routage RDP)
  public_addr: "192.168.20.250:3028"

  ldap:
    # Adresse de l'AD (Port sécurisé 636)
    addr: "192.168.20.150:636"
    domain: "hexaltech.lan"
    username: "svc-teleport"
    # Le SID récupéré à l'étape 3
    sid: "S-1-5-21-438133749-1811766057-640718-1106"
    # Skip la vérification SSL (car certificat AD auto-signé pour l'instant)
    insecure_skip_verify: true

  # Découverte automatique des machines
  discovery_configs:
    - base_dn: "DC=hexaltech,DC=lan"
      # Filtre large pour forcer l'affichage de tous les PC/Serveurs
      filters:
        - "(objectClass=computer)"

```

### Application

Redémarrer le service pour prendre en compte les changements et lancer le scan LDAP :

```bash
sudo systemctl restart teleport

```

---

## 👤 Phase 3 : Gestion des Accès (RBAC)

Par défaut, aucun utilisateur n'a le droit d'ouvrir une session Windows. Il faut créer un rôle.

### Étape 1 : Créer le fichier de rôle

Sur le bastion Linux, créer le fichier `windows-admin.yaml` :

```yaml
kind: role
version: v5
metadata:
  name: windows-admin
spec:
  allow:
    windows_desktop_labels:
      "*": "*"
    # Autorise la connexion en tant qu'Administrateur du domaine
    windows_desktop_logins: ["Administrateur", "administrateur"]

```

### Étape 2 : Appliquer et Assigner

Injecter le rôle dans Teleport et l'donner à l'utilisateur principal (`admin-hexaltech`) :

```bash
# Création du rôle
sudo tctl create -f windows-admin.yaml

# Assignation à l'utilisateur
sudo tctl users update admin-hexaltech --set-roles=access,editor,windows-admin

```

---

## ✅ Phase 4 : Test de Connexion

1. Se connecter à l'interface Web : `https://teleport.hexaltech.fr`.
2. Aller dans l'onglet **Resources > Desktops**.
3. Les machines du domaine (ex: `AD-HEXA`) doivent apparaître.
4. Cliquer sur **Connect** > Sélectionner **Administrateur**.
5. La session RDP s'ouvre directement dans le navigateur sans demande de mot de passe.

---

### 🛠️ Commandes utiles pour le dépannage

* **Voir les logs en temps réel (Linux)** :
```bash
sudo journalctl -u teleport -f

```


* **Vérifier la connectivité LDAPS (Linux)** :
```bash
nc -zv 192.168.20.150 636

```


* **Forcer la mise à jour des GPO (Windows)** :
```powershell
gpupdate /force

```
