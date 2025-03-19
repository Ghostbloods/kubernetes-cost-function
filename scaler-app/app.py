from flask import Flask, request
import os
import base64
import json
from google.auth import default
from google.cloud import container_v1

app = Flask(__name__)

PROJECT_ID = os.environ.get("PROJECT_ID")
CLUSTER_LOCATION = os.environ.get("CLUSTER_LOCATION")
CLUSTER_NAME = os.environ.get("CLUSTER_NAME")

# We'll scale via the GKE API. Alternatively, you can install the kubernetes-python client.
# Then you must also configure Workload Identity or use default application credentials.

@app.route("/", methods=["POST"])
def scaler():
    # Pub/Sub push = JSON with "message" field
    envelope = request.get_json()
    if not envelope or "message" not in envelope:
        return ("Bad request", 400)

    msg = envelope["message"]
    data = ""
    if "data" in msg:
        data = base64.b64decode(msg["data"]).decode("utf-8")

    # Authenticate to the GKE API.
    credentials, _ = default()
    client = container_v1.ClusterManagerClient(credentials=credentials)
    # Get cluster, ensure we have the cluster's endpoint
    cluster = client.get_cluster(project_id=PROJECT_ID, location=CLUSTER_LOCATION, cluster_id=CLUSTER_NAME)
    endpoint = cluster.endpoint  # e.g. "xx.xx.xx.xx"

    # Pretend to scale the Deployment

    print(f"Received alert data: {data}")
    print("Pretending to scale Deployment...")

    # Return success
    return ("Scaled", 200)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
# [END run_pubsub_to_gke_scaler]