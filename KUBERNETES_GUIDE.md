---

````md
# ☸️ Intégration Kubernetes (K3s) avec Teleport

Ce guide décrit l’intégration d’un cluster Kubernetes (ici **K3s**) avec **Teleport** via l’agent officiel **Teleport Kubernetes Agent**, déployé à l’aide de **Helm**.

Cette architecture repose sur un **tunnel inversé** :  
👉 **aucun port entrant n’est exposé** sur le cluster Kubernetes.

---

## 1. Prérequis

- Un cluster Kubernetes fonctionnel (ex. **K3s**)
- **Helm** installé sur le nœud maître du cluster
- Un accès administrateur à **Teleport** (interface Web ou bastion)

---

## 2. Installation de Helm (si nécessaire)

Sur le serveur Kubernetes (K3s), installez Helm :

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
````

Vérification :

```bash
helm version
```

---

## 3. Ajout du dépôt Helm Teleport

```bash
helm repo add teleport https://charts.releases.teleport.dev
helm repo update
```

---

## 4. Déploiement du Teleport Kubernetes Agent

Créer un fichier `values.yaml` minimal :

```yaml
proxyAddr: teleport.example.com:443

authToken: "REPLACE_ME"

kubeClusterName: "k3s-cluster"
```

Installer l’agent :

```bash
helm install teleport-kube-agent teleport/teleport-kube-agent \
  --namespace teleport \
  --create-namespace \
  -f values.yaml
```

---

## 5. Vérification du déploiement

```bash
kubectl get pods -n teleport
```

Les pods doivent être en état `Running`.

---

## 6. Validation côté Teleport

Dans l’interface Teleport :

* Aller dans **Kubernetes**
* Vérifier que le cluster apparaît
* Tester l’accès avec `kubectl` via Teleport

---

## 7. Points clés de sécurité

* Aucun port entrant exposé sur le cluster
* Communication sortante uniquement (tunnel inversé)
* Accès Kubernetes contrôlé via les rôles Teleport

---

## Conclusion

Cette intégration permet d’exposer un cluster Kubernetes **de manière sécurisée**, **sans VPN**, et avec un **contrôle d’accès centralisé** via Teleport.

```

dis-le, je t’envoie ça directement.
```
