🛠️ Project Overview
Goal:
Build a system that monitors and optimizes Kubernetes workloads by automatically scaling down underutilized workloads based on real-time usage patterns.

How It Works:
1️⃣ Monitor Kubernetes usage (CPU, memory, request counts) using Prometheus & Grafana.
2️⃣ Publish usage alerts to Pub/Sub when thresholds are exceeded.
3️⃣ Trigger Cloud Run Functions to take actions (e.g., scale workloads down).
4️⃣ Use Terraform to provision infrastructure and GitHub Actions for automation.

🚀 Step-by-Step Execution Plan
Phase 1: Infrastructure Setup with Terraform
🔹 Set up Google Kubernetes Engine (GKE).
🔹 Deploy Cloud Pub/Sub for event-driven alerts.
🔹 Provision Cloud Run Functions for executing scaling actions.

Phase 2: Monitoring and Data Collection
🔹 Deploy Prometheus & Grafana (via Helm) for real-time monitoring.
🔹 Collect CPU, memory, and request metrics from workloads.
🔹 Set threshold-based alerting using Prometheus rules.

Phase 3: Automating Cost Optimization
🔹 Set up a Kubernetes Controller (Python/Go) that listens to Pub/Sub alerts.
🔹 Reduce replica counts of workloads based on thresholds.
🔹 Implement automatic re-scaling when needed.

Phase 4: CI/CD Pipeline with GitHub Actions
🔹 Automate Terraform deployments.
🔹 Automate Kubernetes manifests & Helm chart updates.
🔹 Validate changes before deployment.

===============================================================================================
# Sign in to Google Cloud
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default login
gcloud auth login

# Enable APIs
gcloud services enable compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  cloudfunctions.googleapis.com \
  pubsub.googleapis.com

# Create Service Acoount
gcloud iam service-accounts create terraform-sa-123 \
    --description="Terraform service account" \
    --display-name="Terraform Service Account"

# Assign Roles to service account
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"   

# Download Service Account Credentials
gcloud iam service-accounts keys create terraform-key.json \
    --iam-account terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com

# Create Kubernetes Cluster using Terraform. 

# Authenticate and retrieve access credentials for kubernetes cluster
gcloud container clusters get-credentials cost-optimizer-cluster --region us-central1 --project (project id)

# Verify nodes are running 
kubectl get nodes

# Deploy a sample application 
touch nginx-deployment.yaml
cat > nginx-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
 
# Apply the deployment 
 kubectl apply -f nginx-deployment.yaml

# Check if the deployment is running
kubectl get pods

# Allow Nginx to be accessable 
kubectl expose deployment nginx-deployment --type=LoadBalancer --port=80 --target-port=80

### Using Helm to deploy Graffana and Prometheus ###

# Add the Nginx Ingress Helm repository
helm repo add nginx https://helm.nginx.com/stable

# Update Helm repository to grab the latest charts
helm repo update

# Install Nginx Ingress Controller using Helm
helm install nginx-ingress nginx-stable/nginx-ingress --namespace default --set controller.replicaCount=2 --set controller.service.type=LoadBalancer

# What this does
Installs the Nginx Ingress Controller from the official Helm chart.
Deploys 2 replicas for high availability.
Exposes the service as a LoadBalancer, making it publicly accessible.

# Make sure Deployment is running and check services
kubectl get pods 
kubectl get services

# Add the Prometheus repo 
helm repo add prometheus https://prometheus-community.github.io/helm-charts

# Update the repo
helm repo update

# To keep things organized, create a seperate namespace for monitoring 
kubectl create namespace monitoring

# Deploy Kube-Prometheus stack that includes Prometheus, Grafana, and AlertManager
helm install prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring

# Verify Deployment and services
kubectl get pods -n monitoring
kubectl get services -n monitoring

# Get Grafana Password prom-operator
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward Grafana to be locally run. 
kubectl port-forward -n monitoring service/prometheus-stack-grafana 3000:80

# Port forward Prometheus
kubectl port-forward -n monitoring statefulset/prometheus-prometheus-stack-kube-prom-prometheus 9090:9090

# Run a test query
kube_pod_container_resource_requests_cpu_cores

### Troubleshooting ###
Target Coredns/0 is not scraping. This allows Prometheus to access the metrics for Kubernetes

Checked if CoreDNS is running
kubectl get pods - n kube-system | grep coredns

Turns out that by default GKC uses kube-dns. 

Edited the Helm chart. Turned off coredns and turned on kubedns

# Updated Deployment 
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack -f values.yaml --namespace monitoring

# Confirm Kube-DNS is being monitored
kubectl get servicemonitors -n monitoring

###                         

# Create a .yaml file to detect workloads using less than 10% of requested CPU
I named mine low-utilization-alert.yaml

# Apply alert rul to Prometheus
kubectl apply -f low-utilization-alert.yaml -n monitoring

# Adding a Pub/Sub Topic to our Terraform Script. 


 
