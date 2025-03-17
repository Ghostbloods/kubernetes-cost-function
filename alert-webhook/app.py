from flask import Flask, request, jsonify
from google.cloud import pubsub_v1
import json
import os

app = Flask(__name__)

# Pub/Sub Settings
PROJECT_ID = "kubernetes-cost-project"
TOPIC_ID = "scale-alerts_topic"

# Initialize Pub/Sub client
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)

@app.route('/alert', methods=['POST'])
def recieve_alert():
    alert_data = request.json
    if not alert_data:
        return jsonify({'error': 'Invalid request'}), 400

    # Convert alert data to JSON string 
    message_data = json.dumps(alert_data).encode('utf-8') 

    # Publish message to Pub/Sub
    future = publisher.publish(topic_path, data=message_data)
    future.result() # Make sure the message is published

    return jsonify({"status": "Alert sent to Pub/Sub"}), 200
    

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)