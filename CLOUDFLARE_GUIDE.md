---

# ☁️ Configuration Complète : DNS, Réseau et SSL Wildcard

Ce guide couvre l'intégralité de la mise en service externe de Teleport : La configuration des ports (NAT), l'enregistrements DNS Cloudflare (A et CNAME) et l'automatisation du certificat SSL Wildcard.

---

## 1. Configuration Réseau (NAT / Pare-feu)

Pour que Teleport soit accessible depuis Internet, vous devez configurer une redirection de port (Port Forwarding / NAT) sur votre routeur ou pare-feu vers l'IP locale de votre serveur Teleport.

| Port | Protocole | Usage |
| --- | --- | --- |
| **443** | TCP | **Proxy Web** (Interface UI + App Access + ACME) |
| **3023** | TCP | **SSH Proxy** (Connexion via terminal `tsh login`) |
| **3025** | TCP | **Auth Service** (Connexion des agents/nœuds distants) |

---

## 2. Configuration DNS Cloudflare

Vous devez créer deux enregistrements essentiels dans votre zone DNS `hexaltech.fr` pour pointer vers votre IP publique.

### A. Enregistrement A (Le Bastion)

Lien entre le nom de domaine principal et votre adresse IP publique.

* **Type** : `A`
* **Nom (Name)** : `teleport`
* **Contenu (IPv4)** : `VOTRE_IP_PUBLIQUE`
* **Proxy status** : ☁️ **DNS Only** (Gris)

### B. Enregistrement CNAME (Le Wildcard)

Indispensable pour rediriger toutes les futures applications (ex: `imprimante.teleport...`) vers le bastion sans créer un enregistrement à chaque fois.

* **Type** : `CNAME`
* **Nom (Name)** : `*.teleport`
* **Cible (Target)** : `teleport.hexaltech.fr`
* **Proxy status** : ☁️ **DNS Only** (Gris)

---

## 3. Création du jeton API Cloudflare (SSL)

1. Connectez-vous à Cloudflare.
2. Allez dans **Profil utilisateur** → **Jetons API**.
3. Cliquez sur **Créer un jeton** → modèle **Modifier le DNS de zone**.
4. Configurez :
* **Permissions** : `Zone` → `DNS` → `Modifier`
* **Ressources** : `Inclure` → `Zone spécifique` → `hexaltech.fr`


5. Copiez le jeton généré (il ne sera affiché qu'une seule fois).

---

## 4. Injection sécurisée du jeton sur le serveur

Pour éviter d'écrire le jeton en clair dans le fichier YAML, on utilise une variable d'environnement systemd.

```bash
sudo systemctl edit teleport

```

Ajoutez ce bloc entre les lignes de commentaires :

```ini
[Service]
Environment="CLOUDFLARE_API_TOKEN=VOTRE_JETON_API_ICI"

```

Rechargez la configuration :

```bash
sudo systemctl daemon-reload

```

---

## 5. Configuration ACME dans Teleport

Éditez le fichier `/etc/teleport.yaml` pour activer la gestion automatique :

```yaml
proxy_service:
  enabled: "yes"
  web_listen_addr: 0.0.0.0:443
  public_addr: teleport.hexaltech.fr:443
  acme:
    enabled: "yes"
    email: "contact@hexaltech.fr"

```

---

## 6. Activation et Vérification

Redémarrez le service pour déclencher la demande de certificat SSL :

```bash
sudo systemctl restart teleport

```

Vérifiez les logs pour confirmer le succès de l'opération :

```bash
sudo journalctl -fu teleport | grep -i acme

```

### Test final

Accédez à `https://teleport.hexaltech.fr` depuis un réseau externe. Le cadenas doit être valide (Let's Encrypt) et toutes vos applications sous `*.teleport.hexaltech.fr` seront automatiquement sécurisées.
