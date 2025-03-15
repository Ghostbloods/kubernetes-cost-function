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

