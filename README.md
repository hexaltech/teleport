```markdown
# 🛡️ Teleport Zero Trust Lab - Hexaltech

Ce dépôt contient l'Infrastructure as Code (IaC) et la documentation technique d'un laboratoire de sécurité **Zero Trust** basé sur **Teleport**.

Ce projet démontre comment sécuriser et unifier l'accès à une infrastructure hybride (Linux, Kubernetes, IoT, Windows) sans utiliser de VPN, ni ouvrir de ports, tout en garantissant une traçabilité totale (Audit logs, Replay de sessions).



## 🚀 Fonctionnalités du Lab

* **Authentification SSO** : Connexion centralisée déléguée à **GitHub** (plus de clés SSH locales à gérer).
* **Kubernetes Access (K8s)** : Intégration d'un cluster **K3s** via l'agent Teleport (Helm Chart), utilisant un tunnel inversé sécurisé.
* **HTTPS Universel** : Certificats **SSL Wildcard** automatiques via le challenge DNS-01 de **Cloudflare**.
* **App Access** : Exposition sécurisée d'interfaces web internes (Imprimante, Outils Admin) sans IP publique.
* **Audit & Conformité** : Enregistrement vidéo des sessions terminaux et journalisation des requêtes `kubectl`.

## 📂 Structure du Dépôt

* **`install.sh`** : Script Bash d'automatisation pour déployer le Bastion Teleport sur Debian 12.
* **`CLOUDFLARE_GUIDE.md`** : Procédure pour la mise en place du certificat SSL Wildcard et la gestion du Token API.
* **`KUBERNETES_GUIDE.md`** : Guide d'intégration d'un cluster Kubernetes via Helm (Agent interne).
* **`/config`** : Modèles de fichiers de configuration YAML.

---

## ⚙️ Installation Rapide

### 1. Déploiement du Bastion
Le script `install.sh` installe les dépendances, configure le dépôt APT officiel de Teleport et prépare la structure des fichiers.

```bash
chmod +x install.sh
sudo ./install.sh

```

> [!IMPORTANT]
> Le script est interactif : il vous demandera votre **nom de domaine** (ex: `teleport.hexaltech.fr`) et votre **email** pour la génération des certificats ACME.

### 2. Sécurisation DNS (Cloudflare)

Pour activer le HTTPS sans erreurs de sécurité, suivez le guide dédié :
👉 **[Voir le guide Cloudflare](https://www.google.com/search?q=./CLOUDFLARE_GUIDE.md)**

### 3. Connexion au Cluster Kubernetes

L'intégration ne nécessite aucune modification complexe sur le Bastion. Tout se fait via l'agent Helm sur le cluster cible :
👉 **[Voir le guide Kubernetes](https://www.google.com/search?q=./KUBERNETES_GUIDE.md)**

---

## ⚠️ Personnalisation

Ce projet est configuré pour l'environnement **Hexaltech**. Avant de l'utiliser, adaptez le fichier `/etc/teleport.yaml` :

1. **Identity** : Remplacez `teleport.hexaltech.fr` par votre FQDN.
2. **App Service** : Modifiez les IPs cibles pour vos applications internes (Section `app_service`).
```yaml
app_service:
  apps:
  - name: "mon-app"
    uri: "[http://192.168.1.50](http://192.168.1.50)" # Votre IP locale

```


3. **RBAC** : Ajustez les rôles utilisateurs via `tctl edit role` pour mapper vos équipes GitHub aux droits Kubernetes (`system:masters`, etc.).

---

## 👨‍💻 Défis Techniques Relevés

* **Architecture Agentless vs Agent** : Transition d'une connexion K8s directe (Kubeconfig) vers une architecture **Agent Helm** pour une meilleure robustesse réseau.
* **Routage Inter-VLAN** : Communication sécurisée entre le Bastion (DMZ) et les ressources critiques (K3s, IoT) situées dans des VLANs isolés.
* **Automatisation ACME** : Gestion du cycle de vie des certificats SSL via l'API Cloudflare pour éviter les renouvellements manuels.

---

**Auteur** : Hexaltech - *Lab Zero Trust & DevSecOps*

```

