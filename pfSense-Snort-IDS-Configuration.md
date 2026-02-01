# 🛡️ pfSense Snort IDS Configuration Guide

**Purpose**: Configure Snort Intrusion Detection System to monitor and detect attacks in your cybersecurity lab

**Time Required**: 30 minutes  
**Difficulty**: Intermediate

---

## 📋 Prerequisites

Before starting, ensure:
- ✅ pfSense is installed and accessible
- ✅ Internet connectivity working
- ✅ DNS and DHCP configured
- ✅ You have 30 minutes uninterrupted time

---

## Part 1: Install Snort Package (5 minutes)

### Step 1.1: Access Package Manager

1. Navigate to: **System → Package Manager**
2. Click: **Available Packages** tab
3. In search box, type: `snort`
4. Find: **pfSense-pkg-snort**
5. Click: **Install** button

### Step 1.2: Wait for Installation

- Installation takes 5 minutes
- Don't close the browser
- Wait for "Installation successfully completed" message

✅ **Verification**: Services menu now shows "Snort" option

---

## Part 2: Register for Snort Oinkcode (5 minutes)

### Step 2.1: Create Account

1. Visit: https://www.snort.org/users/sign_up
2. Fill in registration form:
   - Username
   - Email address
   - Password
3. Click: **Sign up**
4. Check email and verify account

### Step 2.2: Get Oinkcode

1. Login to Snort.org
2. Navigate to: https://www.snort.org/oinkcodes
3. Copy your Oinkcode (40+ character string)
4. Save it somewhere safe (you'll need it next)

**Example Oinkcode format**: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0`

---

## Part 3: Configure Global Settings (5 minutes)

### Step 3.1: Access Global Settings

Navigate to: **Services → Snort → Global Settings**

### Step 3.2: Enable Rule Sources

**Enable these free rule sources:**

☑ **Enable Snort GPLv2**
- Free community rules
- Basic attack coverage

☑ **Enable ET Open** (Emerging Threats)
- Excellent free rules
- Covers OWASP Top 10 attacks

☑ **Enable OpenAppID**
- Application detection
- Protocol identification

☑ **Enable FEODO Tracker**
- Botnet detection
- Command & control servers

**Optional (if you have Oinkcode):**
- ☑ Enable Snort VRT
- Paste Oinkcode in "Snort Oinkmaster Code" field

### Step 3.3: Configure Update Schedule

**Update Interval**: Change from "NEVER" to **12 Hours**
- Keeps rules current
- Automatic updates

### Step 3.4: Save Settings

Click: **Save** at bottom of page

✅ **Verification**: Settings saved, ready to download rules

---

## Part 4: Download Rules (10 minutes)

### Step 4.1: Access Updates Tab

Navigate to: **Services → Snort → Updates**

### Step 4.2: Download Rules

1. Click: **Update Rules** button
2. Wait 5-10 minutes for download
3. Watch progress messages
4. Don't close browser during download

**You'll see messages like:**
```
Downloading Snort VRT rules...
Downloading Emerging Threats rules...
Extracting rules...
Processing rules...
Update completed successfully
```

### Step 4.3: Verify Download

**Services → Snort → Updates tab shows:**
- ✅ Snort GPLv2 Community Rules - Downloaded
- ✅ Emerging Threats Open Rules - Downloaded  
- ✅ Snort OpenAppID Detectors - Downloaded
- ✅ Feodo Tracker Botnet C2 IP Rules - Downloaded
- **Last Update**: Recent timestamp
- **Result**: Success

✅ **Verification**: All rule sets show download dates and "Success" status

---

## Part 5: Add WAN Interface (2 minutes)

### Step 5.1: Access Snort Interfaces

Navigate to: **Services → Snort → Snort Interfaces**

### Step 5.2: Add Interface

1. Click: **Add** button (+ icon)
2. You'll see "WAN Settings" configuration page

---

## Part 6: Configure Interface Settings (5 minutes)

### Section A: General Settings

**Enable**: ☑ **Check this box** (CRITICAL!)
**Interface**: WAN (should be auto-selected)
**Description**: "WAN Monitor" (or any descriptive name)
**Snap Length**: 1518 (leave default)

### Section B: Alert Settings

**Send Alerts to System Log**: ☑ **Check**
- Alerts visible in pfSense system logs
- Easier monitoring

**System Log Facility**: LOG_AUTH (leave default)
**System Log Priority**: LOG_ALERT (leave default)

**Enable Packet Capture**: ☑ **Check**
- Captures attack packets
- Useful for analysis

**Packet Capture File Size**: 128 MB (leave default)

**Enable Unified2 Logging**: ☐ Leave UNCHECKED
- Not needed for basic use

### Section C: Block Settings

**Block Offenders**: ☐ **Leave UNCHECKED**

**Why?** 
- IDS mode (detect only) is better for educational lab
- IPS mode (blocking) might interfere with attack testing
- You want to SEE attacks, not block them

### Section D: Detection Performance Settings

**Leave all defaults** (already optimized):
- Search Method: AC-BNFA
- Split ANY-ANY: Checked
- Search Optimize: Checked
- Stream Inserts: Unchecked
- Checksum Check Disable: Unchecked

### Section E: Networks to Inspect

**Home Net**: default (fine for most cases)
**External Net**: default (fine for most cases)

### Section F: Optional Settings

**Alert Suppression and Filtering**: default
**Custom Configuration Options**: Leave empty

### Step 6.3: Save Settings

Click: **Save** at bottom of page

✅ **Verification**: Interface saved, returns to Snort Interfaces list

---

## Part 7: Configure Rule Categories (3 minutes) ⚠️ UPDATED

### Step 7.1: Edit Interface

1. **Services → Snort → Snort Interfaces**
2. Click: **Edit icon** (pencil) next to WAN interface
3. Click: **WAN Categories** tab (at top)

### Step 7.2: Use IPS Policy (RECOMMENDED)

**Automatic Flowbit Resolution**:
- **Resolve Flowbits**: ☑ Check (recommended)
- Automatically enables dependent rules

**Snort Subscriber IPS Policy Selection**:
1. **Use IPS Policy**: ☑ **Check this box**
2. **IPS Policy Selection**: Select **"Security"** or **"Balanced"**

**⚠️ CRITICAL: Do NOT use "Connectivity"**
- "Connectivity" only loads ~96 rules (insufficient for web attacks)
- You need 500+ rules minimum for proper detection

**Recommended Policy Settings**:

| Policy | Rules Loaded | Best For |
|--------|--------------|----------|
| **Security** ✅ | 600-1,000 | Educational labs (RECOMMENDED) |
| **Balanced** ✅ | 300-500 | Good alternative |
| **Connectivity** ❌ | ~96 | Too minimal - avoid |
| **Max-Detect** ⚠️ | 5,000+ | Too many alerts |

**Why "Security" policy?**
- ✅ Comprehensive rule coverage
- ✅ Includes web attack detection
- ✅ SQL injection, XSS, directory traversal
- ✅ Not too aggressive (unlike Max-Detect)
- ✅ Suitable for educational testing

**Policy Options Explained**:
- **Security**: Stricter, better coverage (RECOMMENDED)
- **Balanced**: Middle ground (good alternative)
- **Connectivity**: Minimal coverage (avoid)
- **Max-Detect**: Very aggressive, alert overload

### Step 7.3: Verify Rule Count (IMPORTANT!)

**After saving, you MUST verify rules loaded**:

1. Go to: **Services → Snort → Snort Interfaces**
2. Click: **Edit** (pencil) on WAN interface
3. Go to: **WAN Rules** tab
4. Scroll to bottom: **Category Rules Summary**
5. Check: **Total Rules**

**Target rule counts**:
- ✅ **600-1,000 rules**: Excellent (Security policy)
- ✅ **300-500 rules**: Good (Balanced policy)
- ⚠️ **96 rules**: Too few (change to Security)
- ❌ **0-50 rules**: Configuration error

**If only 96 rules or less**:
1. Go back to Categories tab
2. Change from "Connectivity" to "Security"
3. Save and restart interface
4. Re-check rule count

### Alternative: Manual Category Selection (Advanced)

**⚠️ Warning**: Manual selection can conflict with IPS Policy

If IPS Policy doesn't work (shows error "Category auto-disabled by SID Mgmt"):

1. **Uncheck "Use IPS Policy"**
2. **Manually select these categories**:
   - ☑ emerging-sql.rules
   - ☑ emerging-web_server.rules
   - ☑ emerging-web_specific_apps.rules
   - ☑ emerging-attack_response.rules
   - ☑ emerging-exploit.rules
   - ☑ emerging-web_client.rules

3. **Save and verify rule count** (should be hundreds/thousands)

**But IPS Policy approach is easier and more reliable!**

### Step 7.4: Save Configuration

Click: **Save** at bottom

✅ **Verification**: Rules configured, ready to start

---

## Part 8: Start Snort Service (1 minute)

### Step 8.1: Start Service

1. Navigate to: **Services → Snort → Snort Interfaces**
2. Find your WAN interface row
3. Look for action buttons on right
4. Click: **Green play button** (▶)

### Step 8.2: Wait for Startup

- Wait 10-20 seconds
- Status will change from "STOPPED" to "RUNNING"
- Green checkmark appears

✅ **Verification**: Status shows green checkmark ✓ and "RUNNING"

---

## Part 9: Verify Snort is Working (5 minutes)

### Verification 1: Check Snort Interfaces

**Services → Snort → Snort Interfaces**

You should see:
- **Interface**: WAN (ena0)
- **Snort Status**: ✓ Green checkmark
- **Pattern Match**: AC-BNFA
- **Blocking Mode**: DISABLED
- **Description**: WAN Monitor

### Verification 2: Check System Services

**Status → Services**

Scroll down, find "snort":
- Status should show: **running**
- If not, something is wrong

### Verification 3: Check System Logs

**Status → System Logs → System**

Search for "snort", should see:
```
snort: Snort started on WAN (ena0)
snort: Rules loaded: XXXXX
snort: Preprocessors configured
```

**The "Rules loaded" number should match your Category Rules Summary count.**

---

## Part 10: Testing & Realistic Expectations ⚠️ UPDATED

### Step 10.1: Understanding Snort Limitations

**⚠️ Important Reality Check**

Snort on pfSense may **NOT** detect all attacks, especially:

**Commonly MISSED attacks**:
- ❌ **SQL injection in HTTP POST body** (requires deep packet inspection)
- ❌ **Complex web application attacks** (JSON/XML payloads)
- ❌ **Encrypted traffic** (HTTPS - can't inspect)
- ❌ **Application-layer attacks** (without specific rules)

**What Snort DOES detect reliably**:
- ✅ **Network-level attacks** (port scans, SYN floods)
- ✅ **SQL injection in URL parameters** (GET requests)
- ✅ **Known malware signatures**
- ✅ **System update traffic** (APT user-agents)
- ✅ **SSL/TLS protocol anomalies**
- ✅ **Directory traversal attempts**
- ✅ **Reconnaissance activity**

### Step 10.2: Perform Test Attacks from Kali

**Test 1: SQL Injection (POST) - May Not Trigger**

```bash
# From Kali
curl -X POST http://10.0.3.100:3000/rest/user/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'\'' OR 1=1--","password":"anything"}'
```

**Expected**: Attack succeeds, but **Snort may not alert** (POST body limitation)

**Test 2: SQL Injection (GET) - More Likely to Trigger**

```bash
# From Kali
curl "http://10.0.3.100:3000/rest/products/search?q=' OR 1=1--"
```

**Expected**: Attack in URL parameters - **better detection chance**

**Test 3: Directory Traversal**

```bash
curl "http://10.0.3.100:3000/ftp/%2e%2e%2f%2e%2e%2fetc/passwd"
```

**Test 4: Nikto User Agent (Should Always Trigger)**

```bash
curl -A "Nikto/2.1.5" http://10.0.3.100:3000/
```

**This should definitely alert** - proves rules are active

**Wait 1-2 minutes** after each attack for Snort to process

### Step 10.3: Check for Alerts (Realistic Approach)

**Services → Snort → Alerts**

1. **Interface**: Select correct interface (WAN or LAN)
2. Click: **View** button
3. **Look for ANY alerts** (not just your specific attack)

**You may see alerts for**:
- ✅ System updates (ET POLICY GNU/Linux APT User-Agent)
- ✅ SSL/TLS anomalies (Invalid Client HELLO)
- ✅ Protocol violations
- ✅ Network reconnaissance
- ⚠️ May NOT see: SQL injection in POST body

**If you see ANY alerts**: ✅ **Snort is working!**

**Example real-world alerts**:
```
ET POLICY GNU/Linux APT User-Agent Outbound
(spp_ssl) Invalid Client HELLO after Server HELLO Detected
```

**These prove Snort is monitoring and detecting!**

### Step 10.4: What If No SQL Injection Alerts?

**This is NORMAL and ACCEPTABLE for coursework!**

**For Your Report**:
1. **Document configuration** ✅ (you completed all steps)
2. **Show Snort IS working** ✅ (any alerts prove this)
3. **Explain limitation** ✅ ("POST body inspection limitation")
4. **Use Wireshark** ✅ (captures actual attack payload)

**Professional approach**:
```
"Snort IDS configured successfully with 651 active rules. System 
detected network-level traffic including APT user-agents and SSL 
anomalies, demonstrating operational monitoring capability. SQL 
injection in POST body not detected due to deep packet inspection 
limitations, requiring complementary analysis with Wireshark for 
application-layer attack verification."
```

**This shows**:
- ✅ Professional understanding
- ✅ Tool awareness
- ✅ Multi-layered approach
- ✅ Real-world experience

### Step 10.5: Interpret Alert Examples

**Alert fields explained**:
```
2026-02-01 10:10:27 [**] [1:2013504:4] ET POLICY GNU/Linux APT User-Agent 
Outbound likely related to package management [**] 
[Classification: Not Suspicious Traffic] [Priority: 3] 
{TCP} 10.0.1.7:24680 -> 3.78.206.74:443
```

- **Timestamp**: When detected (2026-02-01 10:10:27)
- **Rule ID**: 1:2013504:4 (Emerging Threats rule)
- **Description**: APT package manager detected
- **Classification**: Not Suspicious (informational)
- **Priority**: 3 (low priority, 1 = high)
- **Protocol**: TCP
- **Source**: 10.0.1.7:24680 (pfSense performing updates)
- **Destination**: 3.78.206.74:443 (Ubuntu repository)

**This alert proves Snort is working!**

---

## Part 11: Alternative Testing Methods ⚠️ NEW

If primary attacks don't generate alerts, try these **guaranteed detection** methods:

### Test 1: Nmap Port Scan

```bash
# From Kali
nmap -sS 10.0.3.100
```

**Should trigger**: Port scan detection rules

### Test 2: XSS in URL

```bash
curl "http://10.0.3.100:3000/rest/products/search?q=<script>alert(1)</script>"
```

**Should trigger**: XSS attempt detection

### Test 3: User-Agent Based Detection

```bash
# Known attack tools
curl -A "sqlmap/1.0" http://10.0.3.100:3000/
curl -A "Metasploit" http://10.0.3.100:3000/
curl -A "w3af.org" http://10.0.3.100:3000/
```

**These always trigger** - proves rules active

### For Coursework: Combined Approach

**Use Snort + Wireshark together**:

1. **Snort**: 
   - Show configuration screenshots
   - Document any alerts generated (even system updates)
   - Explain what was detected and why

2. **Wireshark**: 
   - Capture actual SQL injection payload
   - Show HTTP POST body with `' OR 1=1--`
   - Prove attack succeeded

3. **Report**: 
   - "Multi-layered detection approach"
   - "Snort for network-level monitoring"
   - "Wireshark for application-layer analysis"

**This demonstrates**:
- ✅ Professional security analysis
- ✅ Understanding of tool limitations  
- ✅ Multiple verification methods
- ✅ Real-world approach

---

## ✅ Success Criteria (Updated)

Your Snort IDS is fully operational when:

- ✅ Snort service shows "RUNNING" status
- ✅ Green checkmark visible in Snort Interfaces
- ✅ System logs show "Snort started"
- ✅ **Rule count 500+ in Category Rules Summary**
- ✅ **Snort generates alerts** (any type proves it works)
- ⚠️ SQL injection alerts optional (POST body limitation acceptable)

**Total configuration time**: ~30 minutes

**Realistic outcome**: Snort configured and detecting network traffic ✅

---

## 📊 Monitoring Snort

### View Real-Time Alerts

**Services → Snort → Alerts**
- Select interface: WAN or LAN
- Click: View
- Enable: Auto-refresh view
- Refresh interval: 30 seconds

### Export Alerts for Coursework

**Services → Snort → Alerts**
1. Select interface
2. Click: **Download** button (green)
3. Saves alerts as text file
4. **Do this for each interface**

### View Alert Details

Click on any alert row to see:
- Full packet capture
- Rule that triggered
- Source/destination details
- Payload content (if captured)

### View Statistics

**Services → Snort → Interfaces**
- Shows packet counts
- Processing statistics
- Alert counts
- Interface status

---

## 🔧 Troubleshooting (Updated)

### Issue: Only 96 rules loaded (or very few) ⚠️ COMMON

**Symptoms**: Category Rules Summary shows "Total Rules: 96" or similarly low number

**Cause**: "Connectivity" IPS policy is too minimal

**Solution**:
1. Services → Snort → Snort Interfaces → Edit interface
2. Go to: **Categories** tab
3. **Change IPS Policy**: From "Connectivity" to **"Security"**
4. Click **Save**
5. Services → Snort → Snort Interfaces
6. **Stop** interface (red square)
7. Wait 10 seconds
8. **Start** interface (green play)
9. Edit → Rules tab → Verify **Category Rules Summary**
10. **Should now show**: 600-1,000 rules

**If still low**:
- Try "Balanced" policy
- Or manually select categories (uncheck "Use IPS Policy" first)

### Issue: Manual category selection shows error

**Symptoms**: Red warning "Category auto-disabled by SID Mgmt conf files"

**Cause**: IPS Policy and manual selection conflict

**Solution**:
1. **Either use IPS Policy OR manual selection, not both**
2. If using IPS Policy: Keep it checked, don't manually select
3. If manual selection: Uncheck "Use IPS Policy" first
4. **Recommended**: Stick with IPS Policy (easier)

### Issue: Snort won't start

**Symptoms**: Status stays "STOPPED", no green checkmark

**Solutions**:
1. Check system logs: Status → System Logs → System
2. Look for error messages mentioning "snort"
3. Common errors:
   - Rules not downloaded → Go to Updates tab, click Update Rules
   - Interface not enabled → Edit interface, check "Enable" box
   - Configuration syntax error → Review all settings
4. Try deleting and re-adding the interface

### Issue: No alerts appearing after attacks

**Symptoms**: Snort running but zero alerts, even after obvious attacks

**Solutions**:
1. **Check rule count**: Should be 500+ minimum
2. **Try guaranteed detection**: Nikto user-agent test
3. **Wait longer**: 3-5 minutes for processing
4. **Check correct interface**: WAN vs LAN
5. **Verify HTTP preprocessor**: Should be enabled (default)
6. **Accept limitation**: POST body inspection may not work

**If still no alerts**:
- Document configuration (proof of work)
- Use Wireshark for traffic analysis
- Explain in report: "Deep packet inspection limitation"

### Issue: Too many alerts (alert fatigue)

**Symptoms**: Thousands of alerts, hard to find real attacks

**Solutions**:
1. Change IPS Policy from "Max-Detect" to "Security"
2. Use Alert Suppression: Services → Snort → Suppress
3. Tune rules to reduce false positives
4. Focus on Priority 1 and 2 alerts (high severity)

### Issue: Rules not updating

**Symptoms**: Old rule dates, no new rules downloading

**Solutions**:
1. Check Oinkcode: Services → Snort → Global Settings
2. Verify internet connectivity from pfSense
3. Manually trigger update: Services → Snort → Updates → Update Rules
4. Check for error messages in update log
5. Ensure rule sources are enabled in Global Settings

### Issue: High CPU usage

**Symptoms**: pfSense slow, high CPU usage

**Solutions**:
1. Status → Monitoring → Check CPU graphs
2. Reduce rule count: Use "Connectivity" instead of "Max-Detect"
3. Disable unnecessary preprocessors
4. Upgrade instance type (t3.small → t3.medium)
5. Monitor with: `top` command in pfSense shell

---

## 🎓 Educational Use Cases

### Scenario 1: Network Monitoring (What Snort Does Best)

**Demonstrate**:
- System update detection (APT user-agents)
- SSL/TLS anomaly detection
- Protocol violations
- Network reconnaissance

**Evidence**:
- Screenshots of detected traffic
- Explain rule logic
- Show legitimate vs suspicious patterns

### Scenario 2: Application Attack Detection (Limited)

**Attempt**:
- SQL injection (may not detect POST body)
- XSS attacks
- Directory traversal

**Document**:
- Configuration efforts
- What was/wasn't detected
- Reasons for limitations
- Alternative analysis with Wireshark

### Scenario 3: Combined Monitoring Approach

**Professional demonstration**:
1. **Snort**: Network-level detection
2. **Wireshark**: Application-layer capture
3. **Analysis**: Explain complementary roles
4. **Report**: Multi-tool security monitoring

**This shows**:
- ✅ Tool expertise
- ✅ Realistic understanding
- ✅ Professional approach
- ✅ Problem-solving skills

---

## 📝 Documentation for Coursework

### Evidence to Collect

1. **Screenshots**:
   - Snort Global Settings (rule sources enabled)
   - Snort Interfaces (showing RUNNING status with green checkmark)
   - Categories tab (IPS Policy "Security" selected)
   - Rules tab (Category Rules Summary showing 500+ rules)
   - Alerts tab (any alerts generated - even system updates)
   - System logs (Snort startup messages)

2. **Exported Files**:
   - Alert logs: Services → Snort → Alerts → Download
   - System logs: Status → System Logs → Download
   - Wireshark captures: .pcap files of attacks

3. **Configuration Documentation**:
   - IPS Policy used ("Security" recommended)
   - Rule count achieved (target 500+)
   - Interfaces monitored (WAN, LAN, or both)
   - Any custom rules or suppressions

### Report Structure

**1. Introduction**:
- Purpose of IDS in network security
- Snort's role in defense-in-depth
- Lab environment overview

**2. Configuration**:
- Installation process
- Rule sources selected (GPLv2, ET Open, etc.)
- IPS Policy choice and justification
- Interface selection (WAN for external, LAN for internal)
- Challenges encountered and solutions

**3. Testing**:
- Attacks performed
- Alerts generated (be honest about results)
- Analysis of detection effectiveness
- Explanation of limitations

**4. Analysis**:
- What Snort detected successfully
- What Snort missed and why
- Comparison with Wireshark captures
- True positives vs false positives

**5. Limitations Identified**:
- POST body inspection challenges
- Application-layer attack detection
- Encrypted traffic (HTTPS) limitations
- Rule tuning requirements

**6. Complementary Approach**:
- How Wireshark fills gaps
- Multi-layered security monitoring
- Professional security analysis methodology

**7. Conclusion**:
- Overall effectiveness of Snort IDS
- Lessons learned
- Recommendations for improvement
- Real-world applicability

**8. Appendices**:
- Configuration screenshots
- Sample alert logs
- Wireshark capture analysis

### Professional Honesty

**Good coursework includes**:
- ✅ Honest reporting of results
- ✅ Explanation of limitations
- ✅ Problem-solving approach
- ✅ Alternative solutions

**Bad coursework**:
- ❌ Claiming fake detections
- ❌ Ignoring tool limitations
- ❌ No explanation of failures
- ❌ Incomplete troubleshooting

**Your professor values**:
- Understanding > Perfect results
- Realistic analysis > Fabrication
- Problem-solving > Success only

---

## 🔐 Security Best Practices

### 1. Regular Rule Updates

- Set update interval to 12 hours
- Manual updates before important tests
- Monitor update logs for failures
- Verify rule count after updates

### 2. Alert Review

- Check alerts regularly (daily in production)
- Investigate high-priority alerts immediately
- Document false positives
- Tune rules to reduce noise

### 3. Tuning

- Start with "Security" policy (600-1,000 rules)
- Monitor alert volume
- Suppress known false positives
- Enable additional categories as needed
- Don't use "Max-Detect" unless necessary

### 4. Performance Monitoring

- Watch CPU usage: Status → Monitoring
- Snort can be resource-intensive
- Adjust settings if performance issues
- Consider instance size (t3.small minimum)

### 5. Backup Configuration

- System → Backup & Restore
- Save Snort configuration regularly
- Document custom rules/suppressions
- Export alert logs before shutdown

### 6. Multi-Layered Approach

- Don't rely on Snort alone
- Use Wireshark for detailed analysis
- Combine with firewall logs
- Implement defense-in-depth

---

## 📚 Additional Resources

### Snort Documentation
- Official Snort Manual: https://www.snort.org/documents
- Rule writing guide: https://www.snort.org/faq/readme-rules
- Community forums: https://www.snort.org/community

### pfSense Snort Package
- pfSense documentation: https://docs.netgate.com/pfsense/en/latest/packages/snort/index.html
- Community forum: https://forum.netgate.com/
- Troubleshooting guides: https://forum.netgate.com/topic/snort

### Attack Signatures
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Emerging Threats: https://rules.emergingthreats.net/
- Snort rule database: https://www.snort.org/downloads/#rule-downloads

### Learning Resources
- Snort IDS basics: YouTube tutorials
- Network security fundamentals
- Intrusion detection concepts
- Deep packet inspection techniques

---

## 🎯 Next Steps

After Snort is configured:

### 1. Verify Configuration
- ✅ Check RUNNING status
- ✅ Verify 500+ rules loaded
- ✅ Confirm alerts generating (any type)

### 2. Perform Testing
- Run multiple attack types
- Document what triggers alerts
- Note what doesn't trigger
- Use alternative testing methods

### 3. Collect Evidence
- Export alert logs
- Take configuration screenshots
- Capture traffic with Wireshark
- Document all findings

### 4. Write Analysis
- Explain configuration
- Report results honestly
- Discuss limitations
- Show complementary tools

### 5. Continue Learning
- Experiment with different policies
- Try manual rule selection
- Test blocking mode (carefully!)
- Explore advanced features

---

## 💡 Key Takeaways

### What You Learned

**Technical Skills**:
- ✅ IDS configuration and deployment
- ✅ Rule management
- ✅ Alert analysis
- ✅ Troubleshooting methodology

**Professional Skills**:
- ✅ Tool limitations awareness
- ✅ Multi-layered security approach
- ✅ Honest reporting
- ✅ Problem-solving

**Real-World Experience**:
- ⚠️ Security tools have limitations
- ⚠️ Configuration matters (rule count!)
- ⚠️ Deep packet inspection is challenging
- ⚠️ Multiple tools provide better coverage

### Remember

**Snort is ONE tool in security arsenal**:
- Not perfect for all attacks
- Best for network-level detection
- Requires complementary tools
- Needs continuous tuning

**Your coursework demonstrates**:
- Professional configuration skills
- Understanding of IDS technology
- Realistic security analysis
- Multi-tool approach

**This is valuable real-world experience!**

---

**Configuration Complete!** 🎉

You've successfully configured Snort IDS with realistic expectations and professional understanding of its capabilities and limitations.

**For Coursework**: You have comprehensive configuration evidence and understand the tool's role in network security monitoring.

**Total Time**: ~30 minutes setup + testing and documentation

**Result**: Operational IDS with 500+ rules detecting network traffic ✅
