# ☁️ Configuration d’un certificat SSL wildcard via Cloudflare

Ce guide décrit la mise en place d’un certificat **SSL wildcard** (`*.teleport.votre-domaine.fr`) pour sécuriser l’ensemble d’une infrastructure **Teleport** : proxy web, App Access et applications internes (imprimante, outils web, etc.).

L’automatisation repose sur **ACME + DNS-01 via Cloudflare**, sans exposition de ports supplémentaires.

---

## 1. Pourquoi un certificat wildcard

Sans certificat wildcard, chaque nouvelle application exposée par Teleport (ex. `imprimante-lab.teleport.hexaltech.fr`) entraîne :

* erreurs navigateur **HSTS**
* avertissements « Connexion non privée »
* expérience utilisateur dégradée

Le challenge **DNS-01 Cloudflare** permet à Teleport de prouver la possession du domaine et d’obtenir un certificat valide pour **tous les sous-domaines**, automatiquement.

---

## 2. Création du jeton API Cloudflare

1. Connectez-vous à l’interface Cloudflare.

2. Allez dans **Profil utilisateur** → **Jetons API**.

3. Cliquez sur **Créer un jeton**.

4. Sélectionnez le modèle **Modifier le DNS de zone**.

5. Configurez précisément :

   * **Permissions** : `Zone` → `DNS` → `Modifier`
   * **Ressources de zone** : `Inclure` → `Zone spécifique` → votre domaine (ex. `hexaltech.fr`)

6. Générez le jeton et copiez-le immédiatement.

⚠️ Ce jeton ne sera plus affiché. Conservez-le de manière sécurisée.

---

## 3. Injection sécurisée du jeton sur le bastion

Le jeton **ne doit jamais** être écrit en clair dans `teleport.yaml`. Il est injecté via une variable d’environnement systemd.

### 3.1 Édition du service systemd

```bash
sudo systemctl edit teleport
```

### 3.2 Ajout de la variable d’environnement

Ajoutez le bloc suivant entre les commentaires :

```ini
[Service]
Environment="CLOUDFLARE_API_TOKEN=VOTRE_JETON_API_ICI"
```

### 3.3 Rechargement de systemd

```bash
sudo systemctl daemon-reload
```

---

## 4. Configuration ACME dans Teleport

Éditez le fichier `/etc/teleport.yaml` pour activer ACME :

```yaml
proxy_service:
  enabled: "yes"
  web_listen_addr: 0.0.0.0:443
  public_addr: teleport.hexaltech.fr:443  # À adapter à votre domaine
  acme:
    enabled: "yes"
    email: "contact@hexaltech.fr"         # Email Let's Encrypt
```

Points critiques :

* `public_addr` doit correspondre exactement au FQDN public
* le port **443** doit être accessible côté proxy Teleport

---

## 5. Activation et supervision

Redémarrez Teleport pour déclencher la demande de certificat :

```bash
sudo systemctl restart teleport
```

Surveillez les logs ACME :

```bash
sudo journalctl -fu teleport | grep -i acme
```

Vous devez observer une séquence indiquant l’obtention du certificat wildcard.

---

## 6. Validation finale

Testez immédiatement un sous-domaine exposé via Teleport, par exemple :

```
imprimante-lab.teleport.votre-domaine.fr
```

Le certificat doit être valide, avec un cadenas navigateur sans avertissement.

---

## 🔐 Rappel de sécurité

* Ce jeton autorise la modification de votre DNS public.
* Ne le commitez jamais dans un dépôt Git.
* Évitez les permissions trop larges.
* Utilisez uniquement des variables d’environnement ou un gestionnaire de secrets.
