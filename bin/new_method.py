import sys
import re
import os
import subprocess
import requests
import time
from datetime import datetime

# --- SMART PATH CONFIGURATION ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Logic to prevent \bin\bin\ error
if os.path.basename(BASE_DIR) == "bin":
    ADB_PATH = os.path.join(BASE_DIR, "adb.exe")
    CITY_DB = os.path.join(BASE_DIR, "GeoLite2-City.mmdb")
    ASN_DB = os.path.join(BASE_DIR, "GeoLite2-ASN.mmdb")
else:
    ADB_PATH = os.path.join(BASE_DIR, "bin", "adb.exe")
    CITY_DB = os.path.join(BASE_DIR, "bin", "GeoLite2-City.mmdb")
    ASN_DB = os.path.join(BASE_DIR, "bin", "GeoLite2-ASN.mmdb")

CHECK_INTERVAL = 1.0  # Refresh rate

# --- GEOIP DATABASE SUPPORT ---
try:
    import geoip2.database
    HAS_GEOIP_LIB = True
except ImportError:
    HAS_GEOIP_LIB = False

uid_cache = {}
geo_cache = {}
active_connections = set()

def get_timestamp():
    return datetime.now().strftime("%H:%M:%S")

def get_app_name(uid):
    if not uid or uid == "-" or not uid.isdigit(): return ""
    if uid in uid_cache: return uid_cache[uid]

    if uid in ["0", "1000", "1001"]:
        res = " [System/Root]"
    else:
        try:
            cmd = f'"{ADB_PATH}" shell cmd package list packages --uid {uid} 2>nul'
            stdout = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT).decode().strip()
            if "package:" in stdout:
                package_name = stdout.split(":")[1].split()[0]
                res = f" [{package_name}]"
            else:
                cmd_fb = f'"{ADB_PATH}" shell "dumpsys package | grep -B 1 \'userId={uid}\'" 2>nul'
                out_fb = subprocess.check_output(cmd_fb, shell=True, stderr=subprocess.STDOUT).decode().strip()
                if "Package [" in out_fb:
                    package_name = out_fb.split("[")[1].split("]")[0]
                    res = f" [{package_name}]"
                else:
                    res = f" [UID:{uid}]"
        except:
            res = f" [UID:{uid}]"
    uid_cache[uid] = res
    return res

def get_geo_info(ip):
    if ip.startswith(("10.", "192.168.", "127.", "172.16.")) or ip == "0.0.0.0":
        return "Internal Network"
    if ip in geo_cache: return geo_cache[ip]
    result = "Unknown Organization"
    if HAS_GEOIP_LIB and os.path.exists(CITY_DB) and os.path.exists(ASN_DB):
        try:
            with geoip2.database.Reader(CITY_DB) as city_reader, \
                 geoip2.database.Reader(ASN_DB) as asn_reader:
                c_res = city_reader.city(ip)
                a_res = asn_reader.asn(ip)
                result = f"{a_res.autonomous_system_organization} ({c_res.country.name})"
        except: pass
    if result == "Unknown Organization":
        try:
            r = requests.get(f"http://ip-api.com/json/{ip}?fields=status,country,org", timeout=1.5).json()
            if r.get('status') == 'success':
                result = f"{r.get('org')} ({r.get('country')})"
        except: pass
    geo_cache[ip] = result
    return result

def run_live_monitor():
    global active_connections
    if not os.path.exists(ADB_PATH):
        print(f"[-] ERROR: ADB Not Found at: {ADB_PATH}")
        return

    print("\n" + "="*145)
    print(f"{'TIME':<12} {'EVENT':<8} {'PROTO':<6} {'FOREIGN ADDRESS':<28} {'INTELLIGENCE'}")
    print("-" * 145)

    while True:
        try:
            cmd = f'"{ADB_PATH}" shell netstat -tuapne 2>nul'
            output = subprocess.check_output(cmd, shell=True).decode()
            current_scan_ids = set()
            for line in output.splitlines():
                parts = line.split()
                if len(parts) < 6 or not re.search(r'\d+\.\d+\.\d+\.\d+', line): continue
                proto, foreign, state = parts[0], parts[4], parts[5]
                uid = "0"
                for p in parts[6:]:
                    if p.isdigit():
                        uid = p
                        break
                conn_id = f"{proto}|{foreign}|{uid}"
                current_scan_ids.add(conn_id)
                if conn_id not in active_connections:
                    ip_only = foreign.split(':')[0]
                    geo = get_geo_info(ip_only)
                    app = get_app_name(uid)
                    tag = "[+]" if state == "ESTABLISHED" else "[*]"
                    print(f"[{get_timestamp()}] {tag} NEW    {proto:<6} {foreign:<28} {geo}{app}")
                    active_connections.add(conn_id)
            for old_conn in list(active_connections):
                if old_conn not in current_scan_ids:
                    c_parts = old_conn.split('|')
                    print(f"[{get_timestamp()}] [-] END    {c_parts[0]:<6} {c_parts[1]:<28} (Closed)")
                    active_connections.remove(old_conn)
        except KeyboardInterrupt:
            sys.exit()
        except Exception:
            time.sleep(2) 
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    print("--- Android Forensic Intelligence Monitor ---")
    print(f"[*] ADB Initialized at: {ADB_PATH}")
    run_live_monitor()