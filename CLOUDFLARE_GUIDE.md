Voici le contenu complet du fichier **`CLOUDFLARE_GUIDE.md`**. Tu peux le copier-coller directement dans un nouveau fichier sur ton GitHub.

J'ai structuré le texte en format **Markdown** pur pour qu'il s'affiche parfaitement avec les blocs de code et les icônes sur ton dépôt.

---

```markdown
# ☁️ Guide de Configuration : Certificat SSL Wildcard via Cloudflare

Ce guide détaille la procédure pour sécuriser automatiquement l'ensemble de votre infrastructure Teleport (y compris les applications comme l'imprimante ou les serveurs web internes) à l'aide d'un certificat **SSL Wildcard** (`*.teleport.votre-domaine.fr`).

## 1. Pourquoi un certificat Wildcard ?
Sans certificat Wildcard, chaque nouvelle application ajoutée (ex: `imprimante-lab.teleport.hexaltech.fr`) générera une erreur de sécurité **HSTS** ou **"Connexion non privée"** dans votre navigateur. Le challenge DNS Cloudflare permet à Teleport de prouver qu'il possède le domaine et d'obtenir un certificat valide pour tous les sous-domaines.

## 2. Étape 1 : Création du Jeton (Token) API Cloudflare
1. Connectez-vous à votre interface [Cloudflare](https://dash.cloudflare.com).
2. Allez dans **Profil Utilisateur** > **Jetons API**.
3. Cliquez sur **Créer un jeton** et choisissez le modèle **Modifier le DNS de zone**.
4. Configurez les permissions suivantes :
   - **Permissions** : `Zone` / `DNS` / `Modifier`.
   - **Ressources de zone** : `Inclure` / `Zone spécifique` / `hexaltech.fr` (ou votre domaine).
5. Copiez le jeton généré (ex: `z-unxuz81HP1P7IjS_-...`).

## 3. Étape 2 : Sécurisation du Jeton sur le Bastion
Il est déconseillé d'écrire le jeton en clair dans le fichier de configuration. Nous l'injectons de manière sécurisée dans les variables d'environnement du service système.

1. Ouvrez l'éditeur de configuration du service :
   ```bash
   sudo systemctl edit teleport

```

2. Ajoutez le bloc suivant entre les lignes de commentaires :
```ini
[Service]
Environment='CLOUDFLARE_API_TOKEN=VOTRE_JETON_API_COPIÉ_ICI'

```


3. Sauvegardez (`Ctrl+O`, `Entrée`) et quittez (`Ctrl+X`).
4. Rechargez la configuration système :
```bash
sudo systemctl daemon-reload

```



## 4. Étape 3 : Configuration de Teleport (`teleport.yaml`)

Modifiez votre fichier `/etc/teleport.yaml` pour activer le protocole ACME :

```yaml
proxy_service:
  enabled: "yes"
  web_listen_addr: 0.0.0.0:443
  public_addr: teleport.hexaltech.fr:443 # À adapter selon votre domaine
  acme:
    enabled: "yes"
    email: "contact@hexaltech.fr" # Email pour les alertes Let's Encrypt

```

## 5. Étape 4 : Activation et Monitoring

Redémarrez Teleport pour initier la demande de certificat :

```bash
sudo systemctl restart teleport

```

Surveillez les logs en temps réel pour confirmer le succès du challenge DNS :

```bash
sudo journalctl -fu teleport | grep -i acme

```

> [!SUCCESS]
> Une fois que vous voyez `ACME: obtaining wildcard certificate`, attendez quelques secondes. Rafraîchissez votre page `imprimante-lab.teleport.hexaltech.fr` : le cadenas doit maintenant être vert et la connexion sécurisée !

---

⚠️ **Rappel de sécurité** : Ce jeton permet de modifier votre DNS. Ne le commitez jamais sur un dépôt public. Utilisez des variables d'environnement ou des gestionnaires de secrets.

```
