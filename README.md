# Kubernetes WordPress Deployment

## Table of Contents
1. [Project Files](#project-files)
   1. [Install with Helm](#install-with-helm)
2. [Local Deployment (minikube)](#local-deployment-minikube)
   1. [Prerequisites](#prerequisites)
   2. [Start minikube](#start-minikube)
   3. [Apply the Manifests](#apply-the-manifests)
   4. [Accessing WordPress Locally](#accessing-wordpress-locally)
3. [AWS ECR (Optional): Push Images](#aws-ecr-optional-push-images)
4. [Deployment to EKS](#deployment-to-eks)
   1. [Prerequisites](#prerequisites-1)
   2. [Update Kubeconfig](#update-kubeconfig)
   3. [Create/Use a Namespace](#createuse-a-namespace)
   4. [Apply the Manifests on EKS](#apply-the-manifests-on-eks)
   5. [Potential Gotchas](#potential-gotchas)
      1. [exec format error (Architecture Mismatch)](#exec-format-error-architecture-mismatch)
      2. [StorageClass / PVC Binding Issues](#storageclass--pvc-binding-issues)
      3. [Ingress Validating Webhook Issues (Shared Cluster)](#ingress-validating-webhook-issues-shared-cluster)
5. [Enjoy!](#enjoy)

---

## 1. Project Files

We have several YAML files that define our Kubernetes resources:

1. **mariadb-statefulset.yaml**  
   - Defines a StatefulSet for MariaDB.  
   - Uses environment variables to set root/user/password for the WordPress database.  
   - Mounts a persistent volume for `/var/lib/mysql`.  

2. **mariadb-service.yaml**  
   - Exposes MariaDB internally in the cluster on port 3306.  

3. **wordpress-deployment.yaml**  
   - Defines a Deployment of WordPress pods.  
   - Environment variables for DB host, user, password, DB name.  
   - Uses port 80 for HTTP.  

4. **wordpress-service.yaml**  
   - Creates a Service to point to the WordPress pods internally.  

5. **storageclass.yaml** (Optional)  
   - A custom StorageClass for dynamic provisioning in AWS/EKS.  

6. **ingress.yaml**  
   - An Ingress resource to route traffic from an external address to the WordPress service.  

7. **ingressclass.yaml** (Optional)  
   - An IngressClass object if you want a named class for your Ingress.  

8. **update_kubeconfig.sh** (Optional)  
   - A script that assumes an IAM role and updates your kubeconfig for a specific EKS cluster. 

### 1.1 Install with Helm
- You can install everything in this project using the charts in the `elad-madar-helm` directory:

```sh
git clone https://github.com/EladMadar/Elad-madar-k8s.git
cd elad-madar-helm

helm install my-wordpress . \
  --namespace <namespace-name> \
  --create-namespace
  ```

---

## 2. Local Deployment (minikube)

### 2.1 Prerequisites
- Docker installed (e.g., Docker Desktop).
- `kubectl` installed.
- `minikube` installed:

```sh
brew install minikube
```

### 2.2 Start minikube

```sh
minikube start
kubectl get nodes
```

### 2.3 Apply the Manifests

```sh
kubectl apply -f mariadb-statefulset.yaml
kubectl apply -f mariadb-service.yaml
kubectl apply -f wordpress-deployment.yaml
kubectl apply -f wordpress-service.yaml
kubectl apply -f storageclass.yaml   # optional
kubectl apply -f ingressclass.yaml   # optional
kubectl apply -f ingress.yaml
```

### 2.4 Accessing WordPress Locally

#### Option A: Port-Forward
```sh
kubectl port-forward svc/wordpress-service 8080:80
```
Then open [http://localhost:8080](http://localhost:8080).

#### Option B: NodePort
Modify `wordpress-service.yaml`:
```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

Then apply:
```sh
kubectl apply -f wordpress-service.yaml
minikube ip
```
Open `http://<minikube-ip>:30080`.

#### Option C: Ingress
```sh
minikube addons enable ingress
```

---

## 3. AWS ECR (Optional): Push Images

```sh
aws ecr create-repository --repository-name my-mariadb
aws ecr create-repository --repository-name my-wordpress
```

```sh
aws ecr get-login-password --region us-east-1 |   docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

```sh
docker tag mariadb:10.6 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/my-mariadb:10.6
docker tag wordpress:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/my-wordpress:latest

docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/my-mariadb:10.6
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/my-wordpress:latest
```

---

## 4. Deployment to EKS

### 4.1 Prerequisites
- A working EKS cluster.
- `kubectl` configured for the cluster.

### 4.2 Update Kubeconfig
```sh
./update_kubeconfig.sh
kubectl get nodes
```

### 4.3 Create/Use a Namespace
```sh
kubectl create namespace elad-madar
```

### 4.4 Apply the Manifests on EKS

```sh
kubectl apply -f mariadb-statefulset.yaml -n elad-madar
kubectl apply -f mariadb-service.yaml -n elad-madar
kubectl apply -f wordpress-deployment.yaml -n elad-madar
kubectl apply -f wordpress-service.yaml -n elad-madar
kubectl apply -f storageclass.yaml
kubectl apply -f ingressclass.yaml   # optional
kubectl apply -f ingress.yaml -n elad-madar
```

---

## 5. Potential Gotchas

### 5.1 exec format error (Architecture Mismatch)
```sh
exec /usr/local/bin/docker-entrypoint.sh: exec format error
```
- Ensure your image is built for the correct architecture.

### 5.2 StorageClass / PVC Binding Issues
```sh
kubectl describe pvc <name>
```

### 5.3 Ingress Validating Webhook Issues (Shared Cluster)
```sh
failed calling webhook "validate.nginx.ingress.kubernetes.io"
```
- Use `NodePort` or `port-forward` instead.

---

## 6. Enjoy!

You can now:
- Run WordPress & MariaDB locally with `minikube`.
- Push images to AWS ECR.
- Deploy to an EKS cluster.

Happy containerizing!
