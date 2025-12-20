```markdown
# ☸️ Intégration Kubernetes (K3s) avec Teleport

Ce guide décrit l’intégration d’un cluster Kubernetes (ici **K3s**) avec **Teleport** via l’agent officiel **Teleport Kube Agent** déployé avec Helm.

Cette approche repose sur un **tunnel inversé** : aucun port entrant n’est exposé sur le cluster Kubernetes.

---

## 1. Prérequis

* Cluster Kubernetes fonctionnel (ex. **K3s**).
* Outil **Helm** installé sur le nœud maître du cluster.
* Accès administrateur à l’interface Web de Teleport ou au terminal du bastion.

---

## 2. Installation de Helm (si nécessaire)

Sur le serveur Kubernetes (K3s), installez Helm :

```bash
curl [https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3](https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3) | bash

```

> ℹ️ **Note (K3s)**
> Assurez-vous que Helm utilise le bon kubeconfig :
> ```bash
> export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
> 
> ```
> 
> 

---

## 3. Génération de la commande d’enrôlement

L’installation de l’agent repose sur une commande générée dynamiquement par Teleport, incluant un **token éphémère**.

1. Connectez-vous à l’interface Web de Teleport.
2. Naviguez vers **Resources** → **Add New** → **Kubernetes**.
3. Renseignez les champs suivants :
* **Teleport Service Namespace** : `teleport-agent`
* **Kubernetes Cluster Name** : `k3s-hexaltech`


4. Cliquez sur **Generate Command**.

---

## 4. Déploiement de l’agent Kubernetes

Copiez la commande générée et exécutez-la sur le serveur Kubernetes.
**Note :** L'adresse du proxy a été adaptée à votre domaine.

```bash
# Ajout du dépôt officiel Teleport
helm repo add teleport [https://charts.releases.teleport.dev](https://charts.releases.teleport.dev)
helm repo update

# Installation de l'agent
# Remplacez VOTRE_TOKEN_ICI par le token généré à l'étape 3
helm install teleport-agent teleport/teleport-kube-agent \
  --create-namespace \
  --namespace teleport-agent \
  --set roles=kube \
  --set proxyAddr=teleport.hexaltech.fr:443 \
  --set authToken=VOTRE_TOKEN_ICI \
  --set kubeClusterName=k3s-hexaltech

```

Vérifiez le bon fonctionnement de l’agent :

```bash
kubectl get pods -n teleport-agent

```

Le ou les pods doivent être à l’état **Running**.

---

## 5. Configuration des permissions (RBAC)

Pour autoriser l'utilisateur local `admin-hexaltech` à voir les pods, son rôle doit être mappé au groupe `system:masters`.

### 5.1 Mapping à respecter

Le rôle Teleport doit envoyer ces informations au cluster :

* **Kubernetes Groups** : `system:masters`
* **Kubernetes User** : `admin`

### 5.2 Modification du rôle (Méthode fiable)

L'édition directe (`tctl edit`) pouvant échouer, nous utilisons la méthode par fichier.
Exécutez ceci sur le serveur **Bastion Teleport** :

1. **Exporter le rôle actuel (ici `k8s-admin`) dans un fichier :**
```bash
sudo tctl get roles/k8s-admin > role_k8s_admin.yaml

```


2. **Éditer le fichier :**
```bash
nano role_k8s_admin.yaml

```


Modifiez la section `allow` pour qu'elle corresponde exactement à ceci :
```yaml
allow:
  kubernetes_labels:
    '*': '*'
  kubernetes_groups:
  - system:masters
  kubernetes_users:
  - admin

```


*(Sauvegardez avec Ctrl+O, Entrée, puis quittez avec Ctrl+X)*
3. **Appliquer la modification :**
```bash
sudo tctl create -f role_k8s_admin.yaml --force

```



---

## 6. Accès au Cluster

Vous pouvez accéder au cluster soit via l'interface Web, soit via votre terminal local.

### Option A : Via l'Interface Web (Simple)

1. Connectez-vous sur `https://teleport.hexaltech.fr`.
2. Allez dans l'onglet **Kubernetes**.
3. Cliquez sur **Connect** à côté de `k3s-hexaltech`.
4. Lancez vos commandes (`kubectl get pods -A`) dans le terminal web.

### Option B : Via Terminal (Client tsh)

L’accès se fait depuis votre poste de travail.

**1. Authentification locale (admin-hexaltech) :**

```bash
tsh logout
tsh login --proxy=teleport.hexaltech.fr --user=admin-hexaltech

```

*(Entrez le mot de passe et l'OTP)*.

**2. Connexion au cluster :**

```bash
tsh kube login k3s-hexaltech

```

**3. Vérification :**

```bash
kubectl get pods -A

```

```

```
