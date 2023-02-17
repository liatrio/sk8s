from flask import Flask
import json
import time


app = Flask(__name__)

@app.route('/api/foo', methods=['GET'])
def api():
    message = "Automate all the things!"
    timestamp = int(time.time())

    output = dict()

    output["message"] = message
    output["timestamp"] = timestamp
    
    return json.dumps(output)
