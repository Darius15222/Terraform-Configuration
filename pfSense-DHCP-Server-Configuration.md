# pfSense DHCP Server Configuration Guide

## Overview

This guide covers configuring DHCP Server on pfSense for two internal networks:
- **LAN** (Kali subnet: 10.0.2.0/24)
- **OPT1** (Ubuntu subnet: 10.0.3.0/24)

**Purpose**: Automatically assign IP addresses, DNS servers, and gateway to Kali and Ubuntu instances.

**Prerequisites**:
- DNS Resolver already configured
- LAN and OPT1 interfaces enabled with correct IPs
- Interface subnet masks set to `/24` (not `/32`)

---

## Critical: Interface Subnet Mask Issue

### Common Problem: `/32` Subnet Mask

**Error Message**: "The specified range lies outside of the current subnet"

**Root Cause**: Interface configured with `/32` subnet mask instead of `/24`

**What `/32` means**: Network contains only ONE IP address (just the firewall itself)  
**What `/24` means**: Network contains 254 usable IP addresses (10.0.X.1 - 10.0.X.254)

**How to check**:
1. Go to **Services → DHCP Server → [interface]**
2. Look at the **Subnet** field under "Primary Address Pool"
3. Should show: `10.0.X.0/24` (correct)
4. If shows: `10.0.X.10/32` (wrong - needs fixing)

---

## Fix Interface Subnet Mask (If Needed)

### For LAN Interface:

1. Go to: **Interfaces → LAN**
2. Find **Static IPv4 Configuration** section
3. Locate **IPv4 Address** field showing: `10.0.2.10`
4. Change subnet dropdown **from `/32` to `/24`**:
   - Before: `10.0.2.10` / `32` ← Wrong
   - After: `10.0.2.10` / `24` ← Correct
5. Click **Save**
6. Click **Apply Changes**

### For OPT1 Interface:

1. Go to: **Interfaces → OPT1**
2. Find **Static IPv4 Configuration** section
3. Locate **IPv4 Address** field showing: `10.0.3.10`
4. Change subnet dropdown **from `/32` to `/24`**:
   - Before: `10.0.3.10` / `32` ← Wrong
   - After: `10.0.3.10` / `24` ← Correct
5. Click **Save**
6. Click **Apply Changes**

---

## Part 1: Configure DHCP for LAN (Kali Subnet)

### Step 1: Navigate to DHCP Server

1. Go to: **Services → DHCP Server**
2. Click **LAN** tab at the top

### Step 2: Verify Subnet Information

Check the **Primary Address Pool** section:
- **Subnet**: Should show `10.0.2.0/24`
- **Subnet Range**: Should show `10.0.2.1 - 10.0.2.254`

**If subnet shows `/32`**: Stop here, fix interface subnet mask first (see section above)

### Step 3: Enable DHCP Server

- ☑ Check box: **Enable DHCP server on LAN interface**

**What this does**: Activates DHCP service on the LAN network

**Why needed**: Kali instance will automatically get network configuration instead of manual setup

### Step 4: Configure Address Pool Range

**Setting**: Address Pool Range
- **From**: `10.0.2.100`
- **To**: `10.0.2.200`

**What this does**: Defines pool of 100 IP addresses DHCP can assign to clients

**Why these numbers**:
- Keeps `.1-.99` reserved for static IPs (like pfSense gateway at .10)
- Provides `.100-.200` for DHCP clients
- Kali will get first available: `10.0.2.100`

### Step 5: Configure DNS Servers

**Setting**: DNS Servers (under "Server Options" section)
- **DNS Server 1**: `10.0.2.10`

**What this does**: Tells clients to use pfSense DNS Resolver for domain name resolution

**Why `10.0.2.10`**: This is pfSense's LAN IP address where DNS Resolver is running

### Step 6: Configure Gateway

**Setting**: Gateway (under "Other DHCP Options" section)
- **Gateway**: `10.0.2.10`

**What this does**: Sets default gateway for routing traffic outside the local subnet

**Why critical**: Without correct gateway, clients can't reach internet or other networks

**What happens**:
```
Kali wants to reach google.com
→ Sends traffic to gateway 10.0.2.10 (pfSense)
→ pfSense routes via WAN to internet
→ Response returns via pfSense to Kali
```

### Step 7: Configure Domain Name

**Setting**: Domain Name (under "Other DHCP Options" section)
- **Domain name**: `cyberlab.local`

**What this does**: Provides local domain suffix for internal DNS

**Why useful**: Machines get FQDN like `kali.cyberlab.local`

### Step 8: Save LAN Configuration

1. Scroll to bottom of page
2. Click **Save** button
3. Configuration is now active (no need to reboot pfSense)

---

## Part 2: Configure DHCP for OPT1 (Ubuntu Subnet)

### Step 1: Switch to OPT1 Tab

1. At the top of the DHCP Server page, click **OPT1** tab
2. Page refreshes showing OPT1 settings

### Step 2: Verify Subnet Information

Check the **Primary Address Pool** section:
- **Subnet**: Should show `10.0.3.0/24`
- **Subnet Range**: Should show `10.0.3.1 - 10.0.3.254`

**If subnet shows `/32`**: Stop here, fix OPT1 interface subnet mask first

### Step 3: Enable DHCP Server

- ☑ Check box: **Enable DHCP server on OPT1 interface**

### Step 4: Configure Address Pool Range

**Setting**: Address Pool Range
- **From**: `10.0.3.100`
- **To**: `10.0.3.200`

**Why these numbers**: Same logic as LAN - reserves `.1-.99` for static, provides `.100-.200` for DHCP

**Ubuntu will get**: `10.0.3.100` (first available in range)

### Step 5: Configure DNS Servers

**Setting**: DNS Servers
- **DNS Server 1**: `10.0.3.10`

**Why `10.0.3.10`**: This is pfSense's OPT1 IP where DNS Resolver listens

### Step 6: Configure Gateway

**Setting**: Gateway
- **Gateway**: `10.0.3.10`

**Why critical**: This fixes the routing issue!

**Before DHCP (with AWS DHCP)**:
```
Ubuntu's gateway: 10.0.3.1 (AWS router - doesn't route properly)
Result: Internet doesn't work ❌
```

**After DHCP (with pfSense DHCP)**:
```
Ubuntu's gateway: 10.0.3.10 (pfSense OPT1 - routes correctly)
Result: Internet works ✅
```

### Step 7: Configure Domain Name

**Setting**: Domain Name
- **Domain name**: `cyberlab.local`

### Step 8: Save OPT1 Configuration

1. Scroll to bottom
2. Click **Save** button

---

## Part 3: Apply DHCP Configuration to Instances

After configuring DHCP on pfSense, instances need to release AWS DHCP leases and get new leases from pfSense.

### Method 1: Force DHCP Renewal (Faster)

#### On Ubuntu:

```bash
# Release current DHCP lease (AWS)
sudo dhclient -r ens5

# Get new lease from pfSense
sudo dhclient ens5

# Verify new configuration
ip route show
```

**Expected output**:
```
default via 10.0.3.10 dev ens5  ← pfSense gateway (correct!)
10.0.3.0/24 dev ens5 proto kernel scope link src 10.0.3.100
```

**Before (wrong)**:
```
default via 10.0.3.1 dev ens5  ← AWS gateway (wrong!)
```

#### On Kali:

```bash
# Release current lease
sudo dhclient -r eth0

# Get new lease from pfSense
sudo dhclient eth0

# Verify
ip route show
```

**Expected output**:
```
default via 10.0.2.10 dev eth0  ← pfSense gateway
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.100
```

### Method 2: Reboot Instances (Clean Slate)

```bash
# On Ubuntu or Kali
sudo reboot
```

**After reboot**: Instance automatically gets DHCP lease from pfSense

---

## Part 4: Verification

### Verify DHCP Leases on pfSense

1. Go to: **Status → DHCP Leases**
2. Check for active leases:

**Expected leases**:
```
IP Address      MAC Address         Hostname    Start       End         Online
10.0.2.100     02:xx:xx:xx:xx:xx    kali        [time]      [time]      ✓
10.0.3.100     02:xx:xx:xx:xx:xx    ubuntu      [time]      [time]      ✓
```

**If leases appear**: ✅ DHCP is working correctly

**If leases don't appear**:
- Instances haven't renewed DHCP yet (run `dhclient` commands)
- DHCP not enabled on interface (check configuration)
- Subnet mask still `/32` (fix interface configuration)

---

### Verify Network Configuration on Ubuntu

```bash
# Check IP address
ip addr show ens5
# Should show: inet 10.0.3.100/24

# Check routing table
ip route show
# Should show: default via 10.0.3.10

# Check DNS configuration
resolvectl status
# Should show: Current DNS Server: 10.0.3.10

# Check gateway reachability
ping -c 3 10.0.3.10
# Should receive replies

# Test DNS resolution
nslookup google.com
# Server should be: 10.0.3.10

# Test internet connectivity
curl -I http://google.com
# Should return HTTP headers ✅
```

---

### Verify Network Configuration on Kali

```bash
# Check IP address
ip addr show eth0
# Should show: inet 10.0.2.100/24

# Check routing
ip route show
# Should show: default via 10.0.2.10

# Test DNS
nslookup google.com
# Server: 10.0.2.10

# Test internet
ping -c 3 google.com
# Should work ✅
```

---

## Configuration Summary

### LAN (Kali Subnet) Configuration:

| Setting | Value | Purpose |
|---------|-------|---------|
| Enable DHCP | ☑ Yes | Activate DHCP service |
| Subnet | 10.0.2.0/24 | Network range |
| Address Pool | 10.0.2.100 - 10.0.2.200 | IP range for clients |
| DNS Servers | 10.0.2.10 | Use pfSense DNS |
| Gateway | 10.0.2.10 | Route via pfSense |
| Domain Name | cyberlab.local | Local domain |

### OPT1 (Ubuntu Subnet) Configuration:

| Setting | Value | Purpose |
|---------|-------|---------|
| Enable DHCP | ☑ Yes | Activate DHCP service |
| Subnet | 10.0.3.0/24 | Network range |
| Address Pool | 10.0.3.100 - 10.0.3.200 | IP range for clients |
| DNS Servers | 10.0.3.10 | Use pfSense DNS |
| Gateway | 10.0.3.10 | Route via pfSense |
| Domain Name | cyberlab.local | Local domain |

---

## How DHCP Works in Your Lab

### DHCP Process Flow:

```
1. Ubuntu boots → "I need network configuration!"
   ↓
2. Sends DHCP DISCOVER broadcast on network
   ↓
3. pfSense DHCP server receives request
   ↓
4. pfSense responds with DHCP OFFER:
   - IP Address: 10.0.3.100
   - Subnet Mask: 255.255.255.0 (/24)
   - Gateway: 10.0.3.10
   - DNS Server: 10.0.3.10
   - Domain: cyberlab.local
   - Lease Time: 7200 seconds (2 hours)
   ↓
5. Ubuntu accepts offer (DHCP REQUEST)
   ↓
6. pfSense confirms (DHCP ACK)
   ↓
7. Ubuntu configures network automatically:
   - ip addr add 10.0.3.100/24 dev ens5
   - ip route add default via 10.0.3.10
   - echo "nameserver 10.0.3.10" > /etc/resolv.conf
   ↓
8. Ubuntu has full network connectivity ✅
```

---

## Network Routing After DHCP

### Kali to Internet:

```
Kali (10.0.2.100)
    ↓
Gateway: 10.0.2.10 (pfSense LAN)
    ↓
pfSense routing engine
    ↓
pfSense WAN interface (10.0.1.7)
    ↓
Internet Gateway
    ↓
Internet ✅
```

### Ubuntu to Internet:

```
Ubuntu (10.0.3.100)
    ↓
Gateway: 10.0.3.10 (pfSense OPT1)
    ↓
pfSense routing engine
    ↓
pfSense WAN interface (10.0.1.7)
    ↓
Internet Gateway
    ↓
Internet ✅
```

### Kali to Ubuntu:

```
Kali (10.0.2.100) wants to reach Ubuntu (10.0.3.100)
    ↓
Different subnets → Send to gateway
    ↓
Gateway: 10.0.2.10 (pfSense LAN)
    ↓
pfSense routing table:
  - Destination: 10.0.3.0/24
  - Next hop: Direct (OPT1 interface)
    ↓
pfSense forwards to OPT1 interface (10.0.3.10)
    ↓
Ubuntu (10.0.3.100) receives traffic ✅
```

---

## Why DHCP Is Critical

### Without DHCP (AWS DHCP):

```
❌ Wrong Gateway:
   - Ubuntu uses 10.0.3.1 (AWS router)
   - AWS router doesn't route traffic properly
   - Internet doesn't work

❌ Wrong DNS:
   - Ubuntu uses 10.0.0.2 (AWS DNS)
   - Bypasses pfSense DNS Resolver
   - Can't demonstrate DNS configuration

❌ Manual Configuration:
   - Need to SSH to each instance
   - Manually edit network files
   - Configuration lost on reboot
```

### With DHCP (pfSense DHCP):

```
✅ Correct Gateway:
   - Ubuntu uses 10.0.3.10 (pfSense)
   - Traffic routes properly through pfSense
   - Internet works

✅ Correct DNS:
   - Ubuntu uses 10.0.3.10 (pfSense DNS)
   - All DNS queries go through pfSense
   - Demonstrates proper DNS setup

✅ Automatic Configuration:
   - Instances configure themselves
   - Persistent across reboots
   - Professional network setup
```

---

## Troubleshooting

### Issue: "Range lies outside current subnet" Error

**Cause**: Interface subnet mask is `/32` instead of `/24`

**Solution**:
1. Go to **Interfaces → [interface]**
2. Change subnet mask from `/32` to `/24`
3. Save and apply changes
4. Return to DHCP Server configuration

---

### Issue: DHCP Leases Not Appearing

**Possible causes**:
1. DHCP not enabled on interface
2. Instances haven't renewed leases yet
3. Network connectivity issues

**Solution**:
```bash
# Force DHCP renewal
sudo dhclient -r ens5  # or eth0 on Kali
sudo dhclient ens5

# Check DHCP status
sudo systemctl status systemd-networkd
```

---

### Issue: Instance Still Uses Wrong Gateway

**Check current gateway**:
```bash
ip route show | grep default
```

**If shows `default via 10.0.3.1`**:
1. DHCP lease not renewed yet
2. Force renewal: `sudo dhclient -r ens5 && sudo dhclient ens5`
3. Or reboot: `sudo reboot`

---

### Issue: Internet Works But DNS Doesn't Use pfSense

**Check DNS configuration**:
```bash
resolvectl status
```

**If shows `Current DNS Server: 10.0.0.2`** (AWS DNS):
1. DHCP DNS setting not applied
2. Force renewal
3. Verify pfSense DHCP has DNS Servers set to correct IPs

---

### Issue: Can't Reach pfSense Gateway

**Test gateway**:
```bash
ping -c 3 10.0.3.10  # or 10.0.2.10 for Kali
```

**If fails**:
1. Check pfSense interface is up: **Status → Interfaces**
2. Check security group allows traffic (AWS)
3. Check pfSense firewall rules allow traffic

---

## DHCP Lease Times

### Default Lease Times:

- **Default lease time**: 7200 seconds (2 hours)
- **Maximum lease time**: 86400 seconds (24 hours)

### What This Means:

- Instance gets IP for 2 hours
- After 1 hour, tries to renew with pfSense
- If renewal fails, keeps trying until lease expires
- After expiration, must get new lease

### For Lab Environment:

Default times are fine. Instances maintain leases as long as they're running and pfSense is reachable.

---

## Success Criteria

Your DHCP configuration is working correctly when:

### On pfSense:
- ✅ DHCP enabled on both LAN and OPT1
- ✅ Status → DHCP Leases shows both instances
- ✅ Leases show correct IPs (10.0.2.100, 10.0.3.100)

### On Ubuntu:
- ✅ IP address: 10.0.3.100
- ✅ Gateway: 10.0.3.10
- ✅ DNS: 10.0.3.10
- ✅ Internet: `curl -I http://google.com` works
- ✅ DNS resolution: `nslookup google.com` uses pfSense

### On Kali:
- ✅ IP address: 10.0.2.100
- ✅ Gateway: 10.0.2.10
- ✅ DNS: 10.0.2.10
- ✅ Internet: `ping google.com` works
- ✅ Can reach Ubuntu: `curl http://10.0.3.100:3000`

---

## Coursework Documentation

### Evidence to Collect:

1. **pfSense DHCP Configuration**:
   - Screenshot: Services → DHCP Server → LAN (showing settings)
   - Screenshot: Services → DHCP Server → OPT1 (showing settings)

2. **DHCP Leases**:
   - Screenshot: Status → DHCP Leases (showing active leases)

3. **Instance Network Configuration**:
   - Command output: `ip addr show`
   - Command output: `ip route show`
   - Command output: `resolvectl status` (Ubuntu)

4. **Connectivity Tests**:
   - Command output: `ping google.com`
   - Command output: `nslookup google.com`
   - Command output: `curl -I http://google.com`

---

## Configuration Time

- **LAN DHCP**: 3 minutes
- **OPT1 DHCP**: 3 minutes
- **Apply to instances**: 2 minutes
- **Verification**: 2 minutes

**Total**: ~10 minutes

---

## Completion Checklist

- ✅ Interface subnet masks set to `/24` (not `/32`)
- ✅ DHCP enabled on LAN interface
- ✅ LAN address pool: 10.0.2.100-200
- ✅ LAN gateway: 10.0.2.10
- ✅ LAN DNS: 10.0.2.10
- ✅ DHCP enabled on OPT1 interface
- ✅ OPT1 address pool: 10.0.3.100-200
- ✅ OPT1 gateway: 10.0.3.10
- ✅ OPT1 DNS: 10.0.3.10
- ✅ Instances renewed DHCP leases
- ✅ DHCP leases visible in pfSense
- ✅ Internet connectivity works on both instances
- ✅ DNS resolution uses pfSense

**Status**: ✅ DHCP Configuration Complete
