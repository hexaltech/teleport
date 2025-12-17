### Fichier : `KUBERNETES_GUIDE.md`

```markdown
# ☸️ Intégration Kubernetes (K3s) avec Teleport

Ce guide explique comment connecter un cluster Kubernetes (ici **K3s**) à Teleport en utilisant l'agent officiel **Teleport Kube Agent** via Helm. Cette méthode permet une connexion via un **tunnel inversé**, ne nécessitant aucune ouverture de port entrant sur le pare-feu du cluster.

## 1. Prérequis
- Un cluster Kubernetes fonctionnel (ex: K3s).
- L'outil `helm` installé sur le nœud maître du cluster.
- Un accès administrateur à l'interface Web de Teleport.

## 2. Installation de Helm (Si nécessaire)
Sur le serveur Kubernetes (K3s), installez le gestionnaire de paquets Helm :

```bash
curl [https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3](https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3) | bash

```

> [!NOTE]
> Pour K3s, assurez-vous de définir la variable d'environnement pour que Helm trouve la configuration :
> `export KUBECONFIG=/etc/rancher/k3s/k3s.yaml`

## 3. Génération de la commande d'enrollment

L'installation se fait via une commande générée dynamiquement par Teleport contenant un jeton de sécurité éphémère.

1. Connectez-vous à l'interface Web de Teleport.
2. Allez dans **Resources** > **Add New** > **Kubernetes**.
3. Remplissez les champs :
* **Teleport Service Namespace** : `teleport-agent`
* **Kubernetes Cluster Name** : `k3s-hexaltech` (ou votre nom)


4. Cliquez sur **Generate Command**.

## 4. Déploiement de l'Agent

Copiez la commande générée et exécutez-la sur votre serveur Kubernetes. Elle ressemble à ceci :

```bash
# Ajout du dépôt officiel
helm repo add teleport [https://charts.releases.teleport.dev](https://charts.releases.teleport.dev)
helm repo update

# Installation de l'agent (Exemple générique)
helm install teleport-agent teleport/teleport-kube-agent \
  --create-namespace \
  --namespace teleport-agent \
  --set roles=kube \
  --set proxyAddr=teleport.votre-domaine.fr:443 \
  --set authToken=VOTRE_TOKEN_SECRET_ICI \
  --set kubeClusterName=k3s-hexaltech

```

Vérifiez que l'agent est opérationnel :

```bash
kubectl get pods -n teleport-agent

```

*Le statut doit passer à `Running`.*

## 5. Configuration des Permissions (RBAC)

Pour qu'un utilisateur Teleport puisse agir sur le cluster, son rôle doit être mappé à un groupe Kubernetes.

### Dans l'interface Teleport (Mapping)

Lors de la connexion, Teleport demande quels droits utiliser. Pour un accès administrateur complet :

* **Kubernetes Groups** : `system:masters`
* **Kubernetes User** : `admin`

### Dans le rôle Teleport (YAML)

Assurez-vous que le rôle de l'utilisateur (ex: `access` ou `editor`) autorise ce mapping.
Éditez le rôle via le terminal du Bastion :

```bash
sudo tctl edit role access

```

Ajoutez/Modifiez la section `kubernetes_groups` :

```yaml
allow:
  kubernetes_labels:
    '*': '*'
  kubernetes_groups: ["system:masters", "developers"]

```

## 6. Accès Client (Développeur)

Une fois configuré, l'accès au cluster se fait depuis le poste de travail du développeur (pas depuis le serveur).

**1. Authentification au Bastion :**

```bash
tsh login --proxy=teleport.votre-domaine.fr --auth=github

```

**2. Connexion au Cluster K8s :**

```bash
tsh kube login k3s-hexaltech

```

*Cette commande met à jour automatiquement le fichier `~/.kube/config` local.*

**3. Utilisation standard :**

```bash
kubectl get pods
kubectl exec -it nginx -- /bin/bash

```

Toutes les commandes sont désormais auditées et enregistrées par Teleport.

```
