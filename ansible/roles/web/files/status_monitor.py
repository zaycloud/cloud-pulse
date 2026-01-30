#!/usr/bin/env python3
import time
import shutil
import psutil
import os
import sys

# Paths to files
HTML_DIR = "/var/www/html"
NORMAL_TEMPLATE = "/opt/monitoring/index_normal.html"
CRITICAL_TEMPLATE = "/opt/monitoring/index_critical.html"
TARGET_FILE = "/var/www/html/index.html"

# Threshold for critical status (CPU %)
THRESHOLD = 80.0

def update_status():
    """
    Monitor CPU and update index.html accordingly.
    """
    current_state = "unknown"
    
    print(f"📡 Status Monitor initialized. Watching CPU (Threshold: {THRESHOLD}%)...")
    
    while True:
        try:
            # Measure CPU over 1 second
            cpu_load = psutil.cpu_percent(interval=1)
            
            # Determine logic
            new_state = "critical" if cpu_load > THRESHOLD else "normal"
            
            # Only perform disk I/O if state changes (to save resources)
            if new_state != current_state:
                if new_state == "critical":
                    print(f"🔥 CPU Critical ({cpu_load}%)! Switching to RED ALERT.")
                    shutil.copy(CRITICAL_TEMPLATE, TARGET_FILE)
                else:
                    print(f"✅ CPU Nominal ({cpu_load}%). Switching to NORMAL.")
                    shutil.copy(NORMAL_TEMPLATE, TARGET_FILE)
                
                current_state = new_state
                
        except Exception as e:
            print(f"❌ Error in monitor loop: {e}", file=sys.stderr)
            time.sleep(5)

if __name__ == "__main__":
    update_status()
