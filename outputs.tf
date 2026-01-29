output "pfsense_public_ip" {
  description = "Public IP address to access pfSense web interface"
  value       = aws_eip.wan_eip.public_ip
}

output "pfsense_web_interface" {
  description = "URL to access pfSense web interface"
  value       = "https://${aws_eip.wan_eip.public_ip}"
}

output "ssh_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.ssh_key.filename
}

output "kali_private_ip" {
  description = "Private IP address of Kali Linux instance"
  value       = aws_instance.kali.private_ip
}

output "ubuntu_private_ip" {
  description = "Private IP address of Ubuntu server instance"
  value       = aws_instance.ubuntu.private_ip
}

output "juiceshop_url" {
  description = "URL to access JuiceShop from Kali Linux"
  value       = "http://${aws_instance.ubuntu.private_ip}:3000"
}

output "cyberchef_url" {
  description = "CyberChef URL (accessible from Kali Linux)"
  value       = "http://localhost:8000 (access from Kali browser)"
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    pfsense = "ssh -i ${local_file.ssh_key.filename} admin@${aws_eip.wan_eip.public_ip}"
    kali    = "ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} kali@${aws_instance.kali.private_ip}"
    ubuntu  = "ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} ubuntu@${aws_instance.ubuntu.private_ip}"
  }
}

output "instance_ids" {
  description = "EC2 Instance IDs for management"
  value = {
    pfsense = aws_instance.pfsense.id
    kali    = aws_instance.kali.id
    ubuntu  = aws_instance.ubuntu.id
  }
}

output "network_architecture" {
  description = "Visual guide to network layout"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║                      NETWORK ARCHITECTURE                       ║
  ╚════════════════════════════════════════════════════════════════╝
  
  ┌──────────────────────────────────────────────────────────────┐
  │                         INTERNET                              │
  └─────────────────────────────┬────────────────────────────────┘
                                │
                                │ Public IP: ${aws_eip.wan_eip.public_ip}
                                │
                  ┌─────────────▼─────────────┐
                  │   pfSense Firewall        │
                  │   WAN: ${var.subnet_cidrs["wan"]}     │
                  │   Access: HTTPS/SSH       │
                  │   Services: DNS, DHCP     │
                  └───────────┬───────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
  ┌──────────────────────┐      ┌──────────────────────┐
  │  LAN (Kali Subnet)   │      │  OPT (Ubuntu Subnet) │
  │  ${var.subnet_cidrs["kali"]}           │      │  ${var.subnet_cidrs["ubuntu"]}           │
  │                      │      │                      │
  │  Gateway: ${local.pfsense_lan_ip}     │      │  Gateway: ${local.pfsense_opt_ip}     │
  └──────────┬───────────┘      └──────────┬───────────┘
             │                             │
             ▼                             ▼
  ┌──────────────────────┐      ┌──────────────────────┐
  │   Kali Linux         │      │   Ubuntu Server      │
  │   IP: ${local.kali_ip}       │      │   IP: ${local.ubuntu_ip}       │
  │   Role: Attacker     │      │   Role: Target       │
  │   Tools:             │      │   Services:          │
  │   - Wireshark        │      │   - JuiceShop:3000   │
  │   - CyberChef:8000   │      │   - Docker           │
  │   - Burp Suite       │      │                      │
  └──────────────────────┘      └──────────────────────┘
  
  ═══════════════════════════════════════════════════════════════
  Security Groups:
  • WAN: ${var.admin_cidr} → pfSense (SSH/HTTPS only)
  • Internal: All VPC traffic allowed between instances
  • Ubuntu: Port 3000 (JuiceShop) explicitly allowed from Kali
  • Egress: Unrestricted (required for lab functionality)
  ═══════════════════════════════════════════════════════════════
  EOT
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region            = var.aws_region
    vpc_cidr          = var.vpc_cidr
    availability_zone = data.aws_availability_zones.available.names[0]
    pfsense_wan_ip    = aws_eip.wan_eip.public_ip
    pfsense_lan_ip    = local.pfsense_lan_ip
    pfsense_opt_ip    = local.pfsense_opt_ip
    kali_ip           = local.kali_ip
    ubuntu_ip         = local.ubuntu_ip
    juiceshop_port    = 3000
    cyberchef_port    = 8000
    project           = var.project_name
    environment       = var.environment
  }
}

output "lab_services" {
  description = "Deployed lab services and access information"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║                      LAB SERVICES DEPLOYED                      ║
  ╚════════════════════════════════════════════════════════════════╝
  
  🔥 PFSENSE FIREWALL (${aws_eip.wan_eip.public_ip})
  ════════════════════════════════════════════════════════════════
  Access: https://${aws_eip.wan_eip.public_ip}
  Default Login: admin / pfsense
  ⚠️  CHANGE PASSWORD IMMEDIATELY!
  
  Services to Configure (Manual - 50 minutes):
    ✓ DNS Resolver (Unbound)
    ✓ DHCP Server (LAN: 10.0.2.100-200, OPT: 10.0.3.100-200)
    ✓ SSL Certificate (Self-signed)
    ✓ Snort IDS (Install via Package Manager)
  
  📋 Configuration Guide: See pfsense-userdata.sh
  
  🐉 KALI LINUX (${aws_instance.kali.private_ip})
  ════════════════════════════════════════════════════════════════
  SSH: ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} kali@${aws_instance.kali.private_ip}
  
  Pre-installed Tools:
    • Wireshark (sudo wireshark)
    • Burp Suite (burpsuite)
    • Metasploit, Nmap, etc.
  
  Deployed Services:
    • CyberChef: http://localhost:8000
      Purpose: Decode/analyze captured data (JWT, Base64, etc.)
  
  📁 Desktop Files:
    • cyberchef.desktop (Firefox shortcut)
    • LAB_TARGETS.txt (Quick reference guide)
  
  🎯 UBUNTU SERVER (${aws_instance.ubuntu.private_ip})
  ════════════════════════════════════════════════════════════════
  SSH: ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} ubuntu@${aws_instance.ubuntu.private_ip}
  
  Deployed Services:
    • JuiceShop: http://${aws_instance.ubuntu.private_ip}:3000
      Purpose: Vulnerable web app for penetration testing
      Vulnerabilities: SQLi, XSS, Broken Auth, Cookie issues, etc.
  
  Docker Container: juiceshop
  Status Check: docker ps
  Logs: docker logs juiceshop
  
  ════════════════════════════════════════════════════════════════
  EOT
}

output "verification_steps" {
  description = "Steps to verify lab is working correctly"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║                    VERIFICATION CHECKLIST                       ║
  ╚════════════════════════════════════════════════════════════════╝
  
  ⏱️  Wait 5-10 minutes after deployment for user-data to complete
  
  ✅ STEP 1: Verify pfSense is accessible
     Command: curl -k https://${aws_eip.wan_eip.public_ip}
     Expected: HTML response (pfSense login page)
  
  ✅ STEP 2: SSH to Kali Linux
     Command: ${aws_instance.kali.id}
     Then: ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} kali@${aws_instance.kali.private_ip}
     Expected: Successful SSH connection
  
  ✅ STEP 3: Verify CyberChef on Kali
     From Kali: curl http://localhost:8000
     Expected: HTML response (CyberChef interface)
  
  ✅ STEP 4: Verify JuiceShop on Ubuntu
     From Kali: curl http://${aws_instance.ubuntu.private_ip}:3000
     Expected: HTML response (JuiceShop homepage)
  
  ✅ STEP 5: Check user-data logs
     Ubuntu: ssh to Ubuntu, then: tail -100 /var/log/userdata.log
     Kali: ssh to Kali, then: tail -100 /var/log/userdata.log
     Expected: "Setup Completed" messages
  
  ✅ STEP 6: Check Docker containers
     Ubuntu: ssh to Ubuntu, then: docker ps
     Expected: juiceshop container running
     Kali: ssh to Kali, then: docker ps
     Expected: cyberchef container running
  
  ✅ STEP 7: Configure pfSense (Manual)
     See: pfsense-userdata.sh for step-by-step guide
     Configure: DNS, DHCP, Certificate, Snort IDS
  
  ════════════════════════════════════════════════════════════════
  
  🚨 TROUBLESHOOTING:
  
  If JuiceShop not responding:
    1. SSH to Ubuntu: ssh -i ${local_file.ssh_key.filename} -J admin@${aws_eip.wan_eip.public_ip} ubuntu@${aws_instance.ubuntu.private_ip}
    2. Check Docker: docker ps
    3. Check logs: docker logs juiceshop
    4. Restart if needed: docker restart juiceshop
  
  If CyberChef not responding:
    1. SSH to Kali
    2. Check Docker: docker ps
    3. Restart if needed: docker restart cyberchef
  
  If pfSense not accessible:
    1. Check AWS Console: EC2 > Instances > ${aws_instance.pfsense.id}
    2. Verify instance is running
    3. Check security group allows your IP: ${var.admin_cidr}
  
  ════════════════════════════════════════════════════════════════
  EOT
}

output "coursework_scenarios" {
  description = "Attack scenarios for coursework documentation"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║              COURSEWORK ATTACK SCENARIOS                        ║
  ╚════════════════════════════════════════════════════════════════╝
  
  📚 SCENARIO 1: SQL Injection + Traffic Capture
  ════════════════════════════════════════════════════════════════
  1. From Kali: sudo wireshark (capture on eth0)
  2. Browser: http://${aws_instance.ubuntu.private_ip}:3000
  3. Login with: ' OR 1=1--
  4. Stop Wireshark capture
  5. Filter: http && tcp.port==3000
  6. Export: File > Export Packet Dissections > sqlinjection.pcap
  
  Documentation:
    ✓ Wireshark capture file
    ✓ Screenshot of malicious payload
    ✓ Screenshot of Snort alert (pfSense > Snort > Alerts)
  
  📚 SCENARIO 2: Cookie Interception
  ════════════════════════════════════════════════════════════════
  1. From Kali: burpsuite
  2. Configure browser proxy: 127.0.0.1:8080
  3. Enable intercept: Proxy > Intercept On
  4. Login to JuiceShop as normal user
  5. Intercept shows Cookie header
  6. Copy JWT token value
  7. Paste in CyberChef: http://localhost:8000
  8. Select operation: JWT Decode
  9. View decoded payload
  
  Documentation:
    ✓ Screenshot of intercepted request in Burp
    ✓ Screenshot of decoded JWT in CyberChef
    ✓ Explanation of cookie structure
    ✓ Demo of cookie reuse/impersonation
  
  📚 SCENARIO 3: DNS/DHCP Demonstration
  ════════════════════════════════════════════════════════════════
  1. Configure pfSense DNS/DHCP (see pfsense-userdata.sh)
  2. From Kali: nslookup google.com
     Expected: Server: 10.0.2.10 (pfSense)
  3. From Kali: ip addr show
     Expected: DHCP-assigned IP in range 10.0.2.100-200
  4. pfSense: Status > DHCP Leases
     Screenshot showing Kali/Ubuntu leases
  
  Documentation:
    ✓ Screenshot of pfSense DHCP config
    ✓ Screenshot of DHCP leases
    ✓ Screenshot of DNS resolver working
  
  📚 SCENARIO 4: IDS Alerts (Snort)
  ════════════════════════════════════════════════════════════════
  1. Configure Snort on pfSense (see guide)
  2. From Kali: perform SQL injection on JuiceShop
  3. From Kali: perform XSS attack
  4. pfSense: Services > Snort > Alerts
  5. Take screenshots of generated alerts
  
  Documentation:
    ✓ Screenshot of Snort configuration
    ✓ Screenshot of multiple alerts
    ✓ Explanation of detected attacks
  
  📚 SCENARIO 5: Certificate Management
  ════════════════════════════════════════════════════════════════
  1. Create self-signed cert in pfSense
  2. Apply to web interface
  3. Access https://${aws_eip.wan_eip.public_ip}
  4. View certificate details in browser
  5. Export certificate for documentation
  
  Documentation:
    ✓ Screenshot of certificate creation
    ✓ Screenshot of certificate details
    ✓ Browser warning (expected for self-signed)
  
  ════════════════════════════════════════════════════════════════
  EOT
}

output "next_steps" {
  description = "What to do after deployment"
  value = <<-EOT
  
  ╔════════════════════════════════════════════════════════════════╗
  ║                         NEXT STEPS                              ║
  ╚════════════════════════════════════════════════════════════════╝
  
  1️⃣  WAIT (5-10 minutes)
      User-data scripts are running in background
      Installing Docker, deploying containers
  
  2️⃣  ACCESS PFSENSE
      URL: https://${aws_eip.wan_eip.public_ip}
      Login: admin / pfsense
      ⚠️  CHANGE PASSWORD IMMEDIATELY
  
  3️⃣  CONFIGURE PFSENSE (50 minutes)
      Follow guide in: pfsense-userdata.sh
      Configure: DNS, DHCP, Certificate, Snort IDS
  
  4️⃣  VERIFY DEPLOYMENT
      Run verification steps above
      Check all services are running
  
  5️⃣  START TESTING
      SSH to Kali Linux
      Access JuiceShop: http://${aws_instance.ubuntu.private_ip}:3000
      Begin penetration testing exercises
  
  6️⃣  DOCUMENT ATTACKS
      Capture traffic with Wireshark
      Collect Snort alerts
      Take screenshots for coursework
  
  ════════════════════════════════════════════════════════════════
  
  💰 COST REMINDER:
  Running cost: ~$0.30/hour (~$7.20/day)
  STOP instances when not in use:
    aws ec2 stop-instances --instance-ids ${aws_instance.pfsense.id} ${aws_instance.kali.id} ${aws_instance.ubuntu.id}
  
  ════════════════════════════════════════════════════════════════
  EOT
}
