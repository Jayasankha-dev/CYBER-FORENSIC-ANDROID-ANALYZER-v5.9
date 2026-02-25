import sys
import re
import geoip2.database
import os
import subprocess

# Paths to the MMDB files inside the 'bin' directory
CITY_DB = 'bin/GeoLite2-City.mmdb'
ASN_DB = 'bin/GeoLite2-ASN.mmdb'

def get_app_name(uid):
    """
    Resolves Android UID to a Package Name using deep system queries.
    """
    if not uid or uid == "-" or not uid.isdigit():
        return ""
    
    # Filter for standard System/Root processes
    if uid in ["0", "1000", "1001"]:
        return " [System/Root]"
        
    try:
        # Method 1: Standard Package Manager Query
        cmd = f"adb shell cmd package list packages --uid {uid}"
        proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, _ = proc.communicate()
        output = stdout.decode().strip()
        
        if "package:" in output:
            # Result format: package:com.example.app uid:12345
            package_name = output.split(":")[1].split()[0]
            return f" [{package_name}]"

        # Method 2: Deep Dumpsys Lookup (Fallback for high UIDs/Work Profiles)
        cmd_fallback = f"adb shell \"dumpsys package | grep -B 1 'userId={uid}'\""
        proc_fb = subprocess.Popen(cmd_fallback, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out_fb, _ = proc_fb.communicate()
        output_fb = out_fb.decode().strip()
        
        if "Package [" in output_fb:
            # Result format: Package [com.example.app]
            package_name = output_fb.split("[")[1].split("]")[0]
            return f" [{package_name}]"
            
        return f" [UID:{uid}]" # Final fallback if name is still hidden
    except:
        return f" [UID:{uid}]"

def get_geo_info(ip):
    """
    Retrieves Geolocation and ASN data for a given IP.
    """
    if ip.startswith(("10.", "192.168.", "127.", "172.16.")) or ip == "0.0.0.0":
        return "Internal/Private Network"
    
    try:
        with geoip2.database.Reader(CITY_DB) as city_reader, \
             geoip2.database.Reader(ASN_DB) as asn_reader:
            
            city_res = city_reader.city(ip)
            asn_res = asn_reader.asn(ip)
            
            country = city_res.country.name if city_res.country.name else "Unknown"
            org = asn_res.autonomous_system_organization if asn_res.autonomous_system_organization else "Unknown Provider"
            
            return f"{org} ({country})"
    except Exception:
        return "Unknown Target"

def process_data(file_path):
    """
    Parses capture files and maps Network Sockets to Geo-Data and App Packages.
    """
    ip_pattern = r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    
    # Header aligned for professional forensic reports
    print("\n" + "="*145)
    print(f"{'PROTO':<6} {'LOCAL ADDRESS':<22} {'FOREIGN ADDRESS':<22} {'STATE':<12} {'ORGANIZATION / LOCATION / [APP PACKAGE]'}")
    print("-" * 145)

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
                        
                        # UID FIX: In 'netstat -tuapne', UID is typically the 7th column (index 6)
                        # We also check if it's a valid digit
                        uid = ""
                        for p in parts[6:]:
                            if p.isdigit():
                                uid = p
                                break
                        
                        geo_data = get_geo_info(ips[1])
                        app_tag = get_app_name(uid)
                        
                        print(f"{proto:<6} {local:<22} {foreign:<22} {state:<12} {geo_data}{app_tag}")
    except Exception as e:
        print(f"[!] Intelligence Engine Error: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        process_data(sys.argv[1])
    else:
        print("Network Intelligence Analyzer")
        print("Usage: python ip_analyzer.py <log_file.txt>")