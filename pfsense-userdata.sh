#!/bin/sh
# ============================================================
# PFSENSE CONFIGURATION GUIDE
# ============================================================
# NOTE: pfSense does not support standard cloud-init/user-data
# automation. This file contains manual configuration steps.
# 
# REQUIRED MANUAL CONFIGURATION (via Web Interface):
# 1. DNS Resolver (Unbound)
# 2. DHCP Server
# 3. SSL Certificate
# 4. Snort IDS Package
# ============================================================

# This script logs the configuration requirements
# It does not automatically configure pfSense

cat > /tmp/pfsense-setup-required.txt <<'EOF'
╔═══════════════════════════════════════════════════════════╗
║          PFSENSE MANUAL CONFIGURATION REQUIRED            ║
╚═══════════════════════════════════════════════════════════╝

⚠️  IMPORTANT: pfSense requires manual configuration via web interface
    URL: https://<PFSENSE_PUBLIC_IP>
    Default credentials: admin / pfsense
    CHANGE PASSWORD IMMEDIATELY!

═══════════════════════════════════════════════════════════
STEP 1: DNS RESOLVER (5 minutes)
═══════════════════════════════════════════════════════════
1. Navigate to: Services > DNS Resolver
2. Enable: ☑ Enable DNS Resolver
3. Enable DNSSEC: ☑ Enable DNSSEC Support
4. Network Interfaces: Select LAN and OPT1
5. Outgoing Network Interface: WAN
6. Click "Save" then "Apply Changes"

✅ Verification:
   - From Kali: ping google.com (should resolve)
   - From Ubuntu: nslookup google.com

═══════════════════════════════════════════════════════════
STEP 2: DHCP SERVER (10 minutes)
═══════════════════════════════════════════════════════════

🔹 LAN Interface (Kali Subnet):
   1. Navigate to: Services > DHCP Server > LAN
   2. Enable: ☑ Enable DHCP server on LAN interface
   3. Range:
      - From: 10.0.2.100
      - To: 10.0.2.200
   4. DNS Servers: 10.0.2.10 (pfSense LAN IP)
   5. Gateway: 10.0.2.10
   6. Domain name: cyberlab.local
   7. Click "Save"

🔹 OPT1 Interface (Ubuntu Subnet):
   1. Navigate to: Services > DHCP Server > OPT1
   2. Enable: ☑ Enable DHCP server on OPT1 interface
   3. Range:
      - From: 10.0.3.100
      - To: 10.0.3.200
   4. DNS Servers: 10.0.3.10 (pfSense OPT IP)
   5. Gateway: 10.0.3.10
   6. Domain name: cyberlab.local
   7. Click "Save"

✅ Verification:
   - Check: Status > DHCP Leases
   - Should see Kali (10.0.2.100) and Ubuntu (10.0.3.100)

═══════════════════════════════════════════════════════════
STEP 3: SSL CERTIFICATE (5 minutes)
═══════════════════════════════════════════════════════════
1. Navigate to: System > Cert Manager > Certificates
2. Click "Add/Sign"
3. Method: Create an Internal Certificate
4. Descriptive name: pfSense Lab Certificate
5. Certificate Type: Server Certificate
6. Common Name: cyberlab.local
7. Country Code: RO
8. State/Province: Sibiu
9. City: Sibiu
10. Organization: CyberLab
11. Lifetime (days): 3650 (10 years)
12. Click "Save"

🔹 Apply Certificate to Web Interface:
   1. Navigate to: System > Advanced > Admin Access
   2. SSL/TLS Certificate: Select "pfSense Lab Certificate"
   3. Click "Save"

✅ Verification:
   - Access https://<PFSENSE_IP>
   - Browser shows your certificate (with warning - normal for self-signed)
   - Click "Advanced" > "Accept Risk and Continue"

═══════════════════════════════════════════════════════════
STEP 4: SNORT IDS (30 minutes)
═══════════════════════════════════════════════════════════

🔹 Install Snort Package:
   1. Navigate to: System > Package Manager
   2. Click "Available Packages"
   3. Search: snort
   4. Click "Install" on Snort package
   5. Wait for installation (5 minutes)
   6. Click "Confirm" when complete

🔹 Register for Snort Rules (FREE):
   1. Go to: https://www.snort.org/users/sign_up
   2. Create free account
   3. Navigate to: Snort.org > Oinkcode
   4. Copy your Oinkcode

🔹 Configure Snort:
   1. Navigate to: Services > Snort > Global Settings
   2. Paste your Oinkcode
   3. Enable: Emerging Threats Open Rules (FREE)
   4. Click "Save"

🔹 Update Rules:
   1. Navigate to: Services > Snort > Updates
   2. Click "Update Rules"
   3. Wait for download (5-10 minutes)

🔹 Enable Snort on WAN:
   1. Navigate to: Services > Snort > Snort Interfaces
   2. Click "Add"
   3. Interface: WAN
   4. Description: WAN Monitor
   5. Enable: ☑ Enable
   6. Click "Save"

🔹 Configure WAN Interface:
   1. Click edit icon (pencil) on WAN interface
   2. WAN Categories tab:
      ☑ Use IPS Policy: Connectivity
   3. WAN Rules tab:
      ☑ Enable all categories
   4. Click "Save"
   5. Click "Start" on WAN interface

✅ Verification:
   - Navigate to: Services > Snort > Alerts
   - Perform test attack from Kali
   - Should see alerts appearing

═══════════════════════════════════════════════════════════
STEP 5: FIREWALL RULES (OPTIONAL - For attack demos)
═══════════════════════════════════════════════════════════

By default, pfSense allows:
- LAN → Any (Kali can access everything)
- OPT1 → Any (Ubuntu can access everything)
- WAN → Blocked (except admin IP)

For attack demonstrations, you may want to:

🔹 Allow Kali → Ubuntu traffic:
   1. Firewall > Rules > LAN
   2. Add rule: Allow TCP/UDP from LAN to OPT1 net
   3. This allows Kali to attack Ubuntu's JuiceShop

🔹 Block Kali → Internet (isolation):
   1. Firewall > Rules > LAN
   2. Add rule: Block from LAN to !RFC1918 (non-private IPs)
   3. This isolates Kali to internal network only

═══════════════════════════════════════════════════════════
TESTING YOUR LAB
═══════════════════════════════════════════════════════════

From Kali Linux:

1️⃣ Test DNS:
   $ nslookup google.com
   # Should resolve via pfSense (10.0.2.10)

2️⃣ Test Internet:
   $ ping 8.8.8.8
   # Should work (via pfSense NAT)

3️⃣ Test JuiceShop:
   $ curl http://10.0.3.100:3000
   # Should return HTML

4️⃣ Launch Attack (SQL Injection):
   $ firefox http://10.0.3.100:3000
   # Login: ' OR 1=1--
   # Check pfSense > Snort > Alerts

5️⃣ Capture Traffic:
   $ sudo wireshark
   # Capture on eth0
   # Filter: tcp.port==3000
   # Export as attack_capture.pcap

═══════════════════════════════════════════════════════════
TROUBLESHOOTING
═══════════════════════════════════════════════════════════

❌ DNS not working:
   - Check: Services > DNS Resolver > Running
   - Check: Status > System Logs > Resolver

❌ DHCP not working:
   - Check: Services > DHCP Server > Enabled
   - Check: Status > System Logs > DHCP

❌ Snort not generating alerts:
   - Check: Services > Snort > WAN interface running
   - Check: Rules are downloaded and enabled
   - Perform obvious attack (SQL injection, XSS)

❌ Can't access JuiceShop from Kali:
   - Check: Ubuntu instance is running
   - Check: docker ps (on Ubuntu via SSH)
   - Check: Firewall rules allow LAN → OPT1

═══════════════════════════════════════════════════════════
ESTIMATED TIME: 50 minutes total
═══════════════════════════════════════════════════════════
EOF

# Log that setup guide was created
logger "pfSense setup guide created at /tmp/pfsense-setup-required.txt"
echo "pfSense requires manual configuration - see /tmp/pfsense-setup-required.txt"
