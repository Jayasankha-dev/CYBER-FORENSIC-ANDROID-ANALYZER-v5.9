# 📱 CYBER-FORENSIC ANDROID ANALYZER v5.9

A powerful, lightweight, and automated Batch-based forensic tool for Android devices. This tool leverages the Android Debug Bridge (ADB) to perform deep system audits, network analysis, and forensic data extraction.

---

## 🚀 Key Features

### 🔍 Forensic Extraction
- **Message Dump:** Extract SMS inbox messages.
- **Contact List:** Dump all saved contacts.
- **Call Logs:** Retrieve call history (includes security bypass for Android 10+).
- **Screenshots:** Real-time screen capture saved directly to PC.

### 🛡️ System & Security Audit
- **Quick Audit:** Get device model, battery health, linked accounts, and uptime.
- **Network Scan:** Monitor live established connections and listening ports.
- **System Integrity:** Scan `/data/local/tmp` for payloads and detect hidden files.
- **Process Manager:** View top 15 resource-consuming processes and RAM usage.

### 📦 Application Management
- **APK Extraction:** Automatically pull installed 3rd-party apps to your PC.
- **App Forensic:** Check hidden/disabled apps and verify package permissions.

### 📂 File Management
- **Smart Multi-Pull:** Select and download multiple folders from `/sdcard/` using a numbered list.
- **Drag & Drop Push:** Easily sideload files or folders from PC to Phone.

### 🧹 Maintenance & Recovery
- **Secure Wipe:** Fill free space with zero-bytes to prevent data recovery.
- **Reboot Options:** Quick access to System, Recovery, and Bootloader (Fastboot).
- **Custom ADB Shell:** Fully interactive manual command interface.

---

## 🛠️ Requirements

- **OS:** Windows 10/11
- **ADB:** Ensure `adb.exe` is in the `bin` folder or added to your System PATH.
- **Device:** Android device with **USB Debugging** enabled.
- **Note for Xiaomi/Oppo/Vivo:** Enable "USB Debugging (Security Settings)" to allow Call Log and SMS extraction.

---

## 📂 Project Structure

```text
├── bin/
│   └── adb.exe (Required)
├── Forensic_Reports/ (Generated)
├── Screenshots/      (Generated)
├── Extracted_Apps/   (Generated)
├── Pulled_Data/      (Generated)
└── android_analyzer.bat
