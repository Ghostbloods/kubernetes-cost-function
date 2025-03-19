from flask import Flask, request
import os
from google.cloud import pubsub_v1

app = Flask(__name__)

PUBSUB_TOPIC = os.environ.get("PUBSUB_TOPIC")
SHARED_SECRET = os.environ.get("SHARED_SECRET", "")
publisher = pubsub_v1.PublisherClient()

@app.route("/alert", methods=["POST"])
def receive_alert():
    # Simple shared-secret check
    req_secret = request.args.get("secret")
    if req_secret != SHARED_SECRET:
        return ("Forbidden", 403)

    data = request.get_data(as_text=True)
    # Publish the raw JSON to Pub/Sub
    topic_path = publisher.topic_path(os.environ["GOOGLE_CLOUD_PROJECT"], PUBSUB_TOPIC)
    future = publisher.publish(topic_path, data.encode("utf-8"))
    future.result()  # Wait for publish

    return ("OK", 200)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
