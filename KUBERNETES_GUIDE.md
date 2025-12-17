# ☸️ Intégration Kubernetes (K3s) avec Teleport

Ce guide décrit l’intégration d’un cluster Kubernetes (ici **K3s**) avec **Teleport** via l’agent officiel **Teleport Kube Agent** déployé avec Helm.

Cette approche repose sur un **tunnel inversé** : aucun port entrant n’est exposé sur le cluster Kubernetes.

---

## 1. Prérequis

* Cluster Kubernetes fonctionnel (ex. **K3s**).
* Outil **Helm** installé sur le nœud maître du cluster.
* Accès administrateur à l’interface Web de Teleport.

---

## 2. Installation de Helm (si nécessaire)

Sur le serveur Kubernetes (K3s), installez Helm :

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

> ℹ️ **Note (K3s)**
> Assurez-vous que Helm utilise le bon kubeconfig :
>
> ```bash
> export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
> ```

---

## 3. Génération de la commande d’enrôlement

L’installation de l’agent repose sur une commande générée dynamiquement par Teleport, incluant un **token éphémère**.

1. Connectez-vous à l’interface Web de Teleport.

2. Naviguez vers **Resources** → **Add New** → **Kubernetes**.

3. Renseignez les champs suivants :

   * **Teleport Service Namespace** : `teleport-agent`
   * **Kubernetes Cluster Name** : `k3s-hexaltech` (ou votre nom de cluster)

4. Cliquez sur **Generate Command**.

---

## 4. Déploiement de l’agent Kubernetes

Copiez la commande générée et exécutez-la sur le serveur Kubernetes. Exemple générique :

```bash
# Ajout du dépôt officiel Teleport
helm repo add teleport https://charts.releases.teleport.dev
helm repo update

# Installation de l'agent
helm install teleport-agent teleport/teleport-kube-agent \
  --create-namespace \
  --namespace teleport-agent \
  --set roles=kube \
  --set proxyAddr=teleport.votre-domaine.fr:443 \
  --set authToken=VOTRE_TOKEN_SECRET_ICI \
  --set kubeClusterName=k3s-hexaltech
```

Vérifiez le bon fonctionnement de l’agent :

```bash
kubectl get pods -n teleport-agent
```

Le ou les pods doivent être à l’état **Running**.

---

## 5. Configuration des permissions (RBAC)

Pour autoriser un utilisateur Teleport à interagir avec le cluster, son rôle doit être mappé à des **groupes Kubernetes**.

### 5.1 Mapping côté Teleport (UI)

Lors de la connexion au cluster via Teleport :

* **Kubernetes Groups** : `system:masters`
* **Kubernetes User** : `admin`

Ce mapping est sélectionné dynamiquement lors de la session.

---

### 5.2 Configuration du rôle Teleport (YAML)

Le rôle Teleport doit explicitement autoriser ces groupes Kubernetes.

Éditez le rôle concerné depuis le bastion Teleport :

```bash
sudo tctl edit role access
```

Ajoutez ou ajustez la section suivante :

```yaml
allow:
  kubernetes_labels:
    '*': '*'
  kubernetes_groups:
    - system:masters
    - developers
```

---

## 6. Accès côté client (développeur)

L’accès au cluster se fait **depuis le poste de travail** de l’utilisateur, jamais directement depuis le serveur Kubernetes.

### 6.1 Authentification au bastion Teleport

```bash
tsh login --proxy=teleport.votre-domaine.fr --auth=github
```

---

### 6.2 Connexion au cluster Kubernetes

```bash
tsh kube login k3s-hexaltech
```

Cette commande met automatiquement à jour le fichier `~/.kube/config` local.

---

### 6.3 Utilisation standard de kubectl

```bash
kubectl get pods
kubectl exec -it nginx -- /bin/bash
```

Toutes les actions Kubernetes sont **auditées**, **journalisées** et **traçables** via Telepo
