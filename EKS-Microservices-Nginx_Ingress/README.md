# 🚀 EKS Microservices with NGINX Ingress

This repository folder contains a complete example of deploying microservices to an **AWS EKS (EC2-backed) Kubernetes cluster**, routed through **NGINX Ingress**. It includes:

- 🧩 Kubernetes manifests (Deployments, Services, Ingress resource)
- 🌐 Architecture diagram (`diagram.png`)
- 🔧 Configuration details for multi-service routing

---

## 📂 Folder Structure

EKS-Microservices-Nginx_Ingress/
├── diagram.png
├── deployment-service-integration.yaml
├── deployment-service-user.yaml
└── ingress-nginx.yaml


---

## 📊 Architecture Diagram

![EKS + Microservices + NGINX Ingress Diagram](diagram.png)

This illustrates:

1. **Users** accessing the public-facing **ALB/NLB**.
2. Traffic routed to the **nginx-ingress-controller** (deployed in-cluster).
3. Ingress routes to individual microservices:
   - `integration-api`
   - `user-api`
4. Each microservice has its own Deployment + Service.

---

## 📄 Manifest Breakdown

### 1. `deployment-service-integration.yaml`

- **Deployment**:  
  - Name: `integration-api`  
  - Replica(s): typically `1` (can scale)  
  - Container: Node.js app exposing `/camps` on port `8083`

- **Service**:  
  - Type: `LoadBalancer`  
  - Dual ports: HTTP (80) and HTTPS (443)  
  - Annotations:
    ```yaml
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp,http"
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "<ARN>"
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
    ```
  - Connects ALB/NLB directly to pods via AWS-managed load balancing

---

### 2. `deployment-service-user.yaml`

- **Deployment**:  
  - Name: `user-api`  
  - Similar replica and container setup (exposes `/users`)

- **Service**:  
  - LoadBalancer fronting the `user-api` pods (mirrors the annotations above for TLS)

---

### 3. `ingress-nginx.yaml`

- **Ingress Resource**:  
  - Metadata annotations to disable SSL redirect:
    ```yaml
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /
    ```
  - **Path-based routing**:
    - `/camps` → `integration-api:80`
    - `/users` → `user-api:80`

💡 Make sure to use **distinct paths** (e.g. `/camps` and `/users`), not both `/`, to ensure proper routing.

---

## ⚙️ How It Works

1. **Ingress Controller** (NGINX): watches the `Ingress` resource and configures routing.
2. **AWS ALB/NLB**: points to the Ingress controller pods via the Service.
3. External traffic flows:
   - `client → ALB/NLB → nginx-ingress → target service`
4. NGINX rewrites and routes based on paths; backend services serve content at expected ports.

---

## ⚠️ Troubleshooting Tips

- **Incorrect path mapping**? If you use identical path (`/`) for both services, NGINX only routes to the first defined service. Use `/camps` and `/users`.
- **SSL not working?** Review `service.beta.kubernetes.io/aws-load-balancer-ssl-cert` annotation. NGINX handles plain HTTP behind AWS TLS termination in this setup.
- **Certificate management**? You can layer in **Cert‑Manager + Let's Encrypt** for real HTTPS within cluster (see Medium tutorial as reference) :contentReference[oaicite:1]{index=1}.

---

## 🛠️ Deployment Steps

1. `kubectl apply -f deployment-service-integration.yaml`
2. `kubectl apply -f deployment-service-user.yaml`
3. Deploy the NGINX Ingress Controller (via Helm or `git apply`).
4. `kubectl apply -f ingress-nginx.yaml`
5. Fetch the public LoadBalancer URL & test:
   - `curl http://<ALB_DNS>/camps`
   - `curl http://<ALB_DNS>/users`

Use HTTPS as needed once TLS is configured.

---

## 🏢 Organizational Benefits of This Setup

- **Scalability**: Individual microservices can be scaled independently to match demand.
- **Modularity**: Path-based routing allows clean separation between service domains.
- **Centralized Ingress**: One Ingress controller handles SSL, routing, and load balancing.
- **Security**: AWS LoadBalancer TLS + eventual cluster TLS via Cert‑Manager.
- **Maintainability**: Versionable manifests + diagram = reproducible, understandable deployments.
- **Cost Efficiency**: EC2-backed EKS provides control; consolidating ingress reduces per-service LB costs.

---

## ✅ Summary

This setup showcases:
- AWS EKS with EC2 nodes hosting two Node.js microservices
- Each service exposed via AWS LBs
- NGINX Ingress for path-based routing
- A foundation for adding TLS (Cert‑Manager) and CI/CD

---

Feel free to adapt: add more microservices, tighten TLS, or integrate CI/CD pipelines for production readiness. 😊

Made by [Zoraiz Ahmad](https://github.com/zoraiz53)
Contact ME on [LINKEDIN](https://www.linkedin.com/in/zoraiz-ahmad-89b402330/)