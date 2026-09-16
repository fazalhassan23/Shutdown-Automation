#!/usr/bin/env python3

import http.server
import json
import os
import subprocess
import glob
from datetime import datetime, timedelta

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

def get_history(username):
    log_dir = f"/home/{username}/shutdown_logs"
    history = {}
    
    # Initialize last 7 days
    for i in range(6, -1, -1):
        d = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
        history[d] = {"offline_events": 0, "shutdowns": 0}
        
    if os.path.exists(log_dir):
        for d in history.keys():
            log_file = os.path.join(log_dir, f"shutdown_{d}.log")
            if os.path.exists(log_file):
                with open(log_file, 'r') as f:
                    content = f.read()
                    history[d]["offline_events"] = content.count("No response from")
                    history[d]["shutdowns"] = content.count("Initiating server shutdown")
                    
    return history

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
        elif self.path == '/api/history':
            config = read_config()
            history = get_history(config.get("USERNAME", "unknown"))
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(history).encode('utf-8'))
        elif self.path == '/api/ping':
            config = read_config()
            target_ip = config.get("TARGET_IP")
            if not target_ip:
                result = {"status": "error", "message": "TARGET_IP not configured"}
            else:
                try:
                    res = subprocess.run(["ping", "-c", "1", "-W", "2", target_ip], capture_output=True, text=True)
                    if res.returncode == 0:
                        result = {"status": "success", "message": f"Ping to {target_ip} successful."}
                    else:
                        result = {"status": "error", "message": f"Ping to {target_ip} failed."}
                except Exception as e:
                    result = {"status": "error", "message": str(e)}
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result).encode('utf-8'))
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/api/config':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            try:
                new_config = json.loads(post_data.decode('utf-8'))
                
                # Read current config to preserve unupdated fields
                config = read_config()
                for key, val in new_config.items():
                    if val is not None and val != "":
                        config[key] = val
                
                # Write back to file
                with open(CONFIG_FILE, 'w') as f:
                    for key, val in config.items():
                        f.write(f'{key}="{val}"\n')
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "success"}).encode('utf-8'))
            except Exception as e:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": str(e)}).encode('utf-8'))
        elif self.path == '/api/action':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode('utf-8'))
                action = data.get("action")
                
                if action == "shutdown":
                    subprocess.run(["shutdown", "-h", "+1", "Manual shutdown triggered from Web UI"])
                    msg = "Shutdown initiated (1 minute delay)."
                    
                    state = read_state()
                    state["shutdown_triggered_at"] = int(datetime.now().timestamp())
                    state["manual_shutdown"] = True
                    with open(STATE_FILE, 'w') as f:
                        json.dump(state, f)
                        
                elif action == "cancel":
                    subprocess.run(["shutdown", "-c"])
                    msg = "Shutdown cancelled."
                    
                    state = read_state()
                    state.pop("shutdown_triggered_at", None)
                    state.pop("manual_shutdown", None)
                    with open(STATE_FILE, 'w') as f:
                        json.dump(state, f)
                else:
                    raise ValueError("Invalid action")
                    
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "success", "message": msg}).encode('utf-8'))
            except Exception as e:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "message": str(e)}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    print(f"Starting web interface on port {PORT}...")
    server = http.server.ThreadingHTTPServer(('', PORT), APIHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nWeb interface stopped.")
