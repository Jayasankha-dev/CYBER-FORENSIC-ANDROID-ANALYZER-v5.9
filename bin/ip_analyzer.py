import sys
import re
import os
import subprocess
import requests

# Try to import geoip2 for local database support
try:
    import geoip2.database
    HAS_GEOIP_LIB = True
except ImportError:
    HAS_GEOIP_LIB = False

# Paths to the MMDB files (Optional)
CITY_DB = 'bin/GeoLite2-City.mmdb'
ASN_DB = 'bin/GeoLite2-ASN.mmdb'

def get_app_name(uid):
    """
    Resolves Android UID to a Package Name.
    Includes logic for System/Root and Kernel Handover.
    """
    if not uid or uid == "-" or not uid.isdigit():
        return ""
    
    # Filter for standard System/Root processes
    if uid in ["0", "1000", "1001"]:
        return " [System/Root]"
        
    try:
        # Method 1: Standard Package Manager Query
        cmd = f"adb shell cmd package list packages --uid {uid}"
        stdout = subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL)
        output = stdout.decode().strip()
        
        if "package:" in output:
            package_name = output.split(":")[1].split()[0]
            return f" [{package_name}]"

        # Method 2: Dumpsys Fallback (For Work Profiles/Parallel Apps)
        cmd_fb = f"adb shell \"dumpsys package | grep -B 1 'userId={uid}'\""
        out_fb = subprocess.check_output(cmd_fb, shell=True, stderr=subprocess.DEVNULL)
        output_fb = out_fb.decode().strip()
        
        if "Package [" in output_fb:
            package_name = output_fb.split("[")[1].split("]")[0]
            return f" [{package_name}]"
            
        return f" [UID:{uid}]" 
    except:
        return f" [UID:{uid}]"

def get_geo_info(ip):
    """
    Retrieves Geolocation/ASN. 
    Priority: Local MMDB > Online API Fallback.
    """
    # Skip private IP ranges
    if ip.startswith(("10.", "192.168.", "127.", "172.16.")) or ip == "0.0.0.0":
        return "Internal/Private Network"
    
    # --- STRATEGY A: Local Database (Offline) ---
    if HAS_GEOIP_LIB and os.path.exists(CITY_DB) and os.path.exists(ASN_DB):
        try:
            with geoip2.database.Reader(CITY_DB) as city_reader, \
                 geoip2.database.Reader(ASN_DB) as asn_reader:
                
                city_res = city_reader.city(ip)
                asn_res = asn_reader.asn(ip)
                
                country = city_res.country.name or "Unknown"
                org = asn_res.autonomous_system_organization or "Unknown Provider"
                return f"{org} ({country})"
        except:
            pass # Move to Strategy B if DB reading fails

    # --- STRATEGY B: Online API (Fallback for GitHub/No-DB users) ---
    try:
        # Using ip-api.com (No API Key Required)
        api_url = f"http://ip-api.com/json/{ip}?fields=status,country,org"
        response = requests.get(api_url, timeout=2).json()
        if response.get('status') == 'success':
            country = response.get('country', 'Unknown')
            org = response.get('org', 'Unknown Provider')
            return f"{org} ({country})"
    except:
        pass

    return "Unknown Organization"

def process_data(file_path):
    """
    Parses 'netstat' capture files and maps Sockets to Geo-Data and Packages.
    """
    ip_pattern = r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    
    # Forensic Report Header
    print("\n" + "="*150)
    print(f"{'PROTO':<6} {'LOCAL ADDRESS':<22} {'FOREIGN ADDRESS':<22} {'STATE':<14} {'ORGANIZATION / LOCATION / [APP PACKAGE]'}")
    print("-" * 150)

    if not os.path.exists(file_path):
        print(f"[!] Error: Source file '{file_path}' not found.")
        return

    try:
        with open(file_path, 'r') as f:
            for line in f:
                line = line.strip()
                ips = re.findall(ip_pattern, line)
                
                if len(ips) >= 2:
                    parts = line.split()
                    if len(parts) >= 5:
                        proto = parts[0]
                        local = parts[3]
                        foreign = parts[4]
                        state = parts[5] if len(parts) > 5 else "N/A"
                        
                        # Extracting UID (usually the 7th column in netstat -e)
                        uid = ""
                        for p in parts[6:]:
                            if p.isdigit():
                                uid = p
                                break
                        
                        # Fetching Intelligence
                        geo_data = get_geo_info(ips[1])
                        app_tag = get_app_name(uid)
                        
                        # Apply "System/Kernel Handover" logic for closing states
                        if uid == "0" and state not in ["LISTEN", "ESTABLISHED"]:
                            app_tag = " [System/Kernel Handover]"
                        
                        print(f"{proto:<6} {local:<22} {foreign:<22} {state:<14} {geo_data}{app_tag}")
    except Exception as e:
        print(f"[!] Intelligence Engine Error: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        process_data(sys.argv[1])
    else:
        print("Network Intelligence Analyzer - v3.0")
        print("Usage: python ip_analyzer.py <log_file.txt>")