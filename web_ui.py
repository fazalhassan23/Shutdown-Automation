#!/usr/bin/env python3

import http.server
import json
import os
from datetime import datetime

PORT = 8080
CONFIG_FILE = "/etc/server-auto-shutdown.conf"
STATE_FILE = "/tmp/auto_shutdown.state"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def read_config():
    config = {}
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            for line in f:
                if "=" in line:
                    key, val = line.strip().split('=', 1)
                    config[key] = val.strip('"\'')
    return config

def read_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            pass
    return {"fail_duration": 0, "timestamp": 0}

def read_logs(username):
    today = datetime.now().strftime("%Y-%m-%d")
    log_file = f"/home/{username}/shutdown_logs/shutdown_{today}.log"
    logs = []
    if os.path.exists(log_file):
        try:
            with open(log_file, 'r') as f:
                # Get last 50 lines
                logs = f.readlines()[-50:]
        except Exception:
            pass
    return [line.strip() for line in logs]

class APIHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def do_GET(self):
        if self.path == '/api/status':
            config = read_config()
            state = read_state()
            logs = read_logs(config.get("USERNAME", "unknown"))
            
            response = {
                "config": config,
                "state": state,
                "logs": logs
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            super().do_GET()

if __name__ == "__main__":
    print(f"Starting web interface on port {PORT}...")
    server = http.server.ThreadingHTTPServer(('', PORT), APIHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nWeb interface stopped.")
