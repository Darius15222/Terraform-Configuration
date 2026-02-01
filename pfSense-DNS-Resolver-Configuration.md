# pfSense DNS Resolver Configuration Guide

## Prerequisites
- pfSense web interface accessible at: `https://<PFSENSE_PUBLIC_IP>`
- LAN and OPT1 interfaces already configured and enabled
- LAN IP: 10.0.2.10/24
- OPT1 IP: 10.0.3.10/24

---

## Step-by-Step Configuration

### Step 1: Navigate to DNS Resolver

1. Log into pfSense web interface
2. Go to: **Services → DNS Resolver**
3. Click on **General Settings** tab (if not already there)

---

### Step 2: Enable DNS Resolver

- ☑ Check the box: **Enable DNS resolver**

**What this does**: Activates pfSense's built-in DNS server (Unbound)

**Why needed**: Allows Kali and Ubuntu to resolve domain names (e.g., google.com → IP address)

---

### Step 3: Configure Network Interfaces

**Setting**: Network Interfaces

**Select the following** (hold Ctrl to select multiple):
- ☑ **LAN**
- ☑ **OPT1**
- ☑ **Localhost**

**Do NOT select**: All, WAN

**What this does**: 
- LAN: Allows Kali subnet (10.0.2.0/24) to use pfSense DNS
- OPT1: Allows Ubuntu subnet (10.0.3.0/24) to use pfSense DNS
- Localhost: Allows pfSense itself to resolve domain names (needed for updates)

**Why NOT WAN**: Don't want external internet users querying your DNS server (security risk)

---

### Step 4: Configure Outgoing Network Interfaces

**Setting**: Outgoing Network Interfaces

**Select**:
- ☑ **WAN** (only WAN)

**What this does**: When pfSense doesn't know an answer, it forwards the DNS query to internet DNS servers via WAN interface

**DNS Flow Example**:
```
Kali asks: "What's google.com?" 
→ pfSense checks local cache
→ Not found, so queries 8.8.8.8 via WAN
→ Gets answer: 142.250.185.78
→ Returns to Kali
```

---

### Step 5: Enable DNSSEC

**Setting**: DNSSEC

- ☑ Check the box: **Enable DNSSEC Support**

**What this does**: Cryptographic validation of DNS responses

**Why needed**: Prevents DNS spoofing attacks (attacker can't redirect google.com to malicious IP)

---

### Step 6: Save Configuration

1. Scroll to bottom of page
2. Click **Save** button
3. Click **Apply Changes** button

**What happens**: pfSense applies the configuration and starts/restarts the Unbound DNS service

---

### Step 7: Verify DNS Resolver Is Running

#### Method 1: Check Services Status

1. Go to: **Status → Services**
2. Find **unbound** in the service list
3. Check status column

**Expected**: Green checkmark with "running" status

**If stopped**: Click **Start** button

---

#### Method 2: Test DNS Resolution from pfSense

1. Go to: **Diagnostics → DNS Lookup**
2. In **Hostname** field, enter: `google.com`
3. Click **Lookup**

**Expected**: Shows IP addresses like:
```
google.com resolves to:
142.250.185.78
2607:f8b0:4004:c07::71
```

**If successful**: ✅ DNS Resolver is working correctly

---

## Configuration Summary

### Final Settings:

| Setting | Value |
|---------|-------|
| Enable DNS resolver | ☑ Enabled |
| Network Interfaces | LAN, OPT1, Localhost |
| Outgoing Network Interfaces | WAN |
| DNSSEC Support | ☑ Enabled |

---

## What DNS Resolver Does

**Before DNS Resolver**:
- Applications can't resolve domain names
- Only direct IP addresses work (e.g., 8.8.8.8)
- Commands like `ping google.com` fail

**After DNS Resolver**:
- Domain names resolve to IP addresses
- Kali/Ubuntu can browse websites
- Commands like `ping google.com` work
- pfSense can download updates/packages

---

## DNS Flow in Your Lab

```
┌─────────┐
│  Kali   │ "What's google.com?"
└────┬────┘
     │
     ▼
┌─────────────────┐
│ pfSense DNS     │ Checks cache → Not found
│ 10.0.2.10       │ 
└────┬────────────┘
     │
     ▼ (via WAN)
┌─────────────────┐
│ Internet DNS    │ "google.com = 142.250.185.78"
│ (e.g., 8.8.8.8) │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ pfSense DNS     │ Caches result
│                 │ Returns to Kali
└────┬────────────┘
     │
     ▼
┌─────────┐
│  Kali   │ Gets IP: 142.250.185.78
└─────────┘
```

---

## Troubleshooting

### Issue: Error "Localhost or All must be selected"

**Cause**: pfSense needs to resolve DNS for itself (updates, package downloads)

**Fix**: Add **Localhost** to Network Interfaces selection

---

### Issue: DNS Resolver shows "No Data" on Status page

**Cause**: Normal initially - no DNS queries processed yet

**Action**: Go to Status → Services and verify **unbound** shows "running"

---

### Issue: Kali/Ubuntu still can't resolve domain names

**Cause**: Instances not using pfSense DNS yet (using AWS DNS instead)

**Fix**: Configure DHCP Server to provide pfSense DNS (10.0.2.10 / 10.0.3.10) to clients

**Check current DNS**:
```bash
# On Ubuntu/Kali
cat /etc/resolv.conf
# Should show: nameserver 10.0.2.10 (or 10.0.3.10)
```

---

## Next Steps

After DNS Resolver configuration:

1. **Configure DHCP Server** (Services → DHCP Server)
   - LAN: Provides DNS 10.0.2.10 to Kali
   - OPT1: Provides DNS 10.0.3.10 to Ubuntu

2. **Renew DHCP on instances** to get pfSense DNS
   ```bash
   sudo dhclient -r ens5
   sudo dhclient ens5
   ```

3. **Test DNS from instances**:
   ```bash
   nslookup google.com
   # Should show: Server: 10.0.2.10 (or 10.0.3.10)
   ```

---

## Completion Checklist

- ✅ DNS Resolver enabled
- ✅ Network Interfaces: LAN, OPT1, Localhost selected
- ✅ Outgoing Interface: WAN selected
- ✅ DNSSEC enabled
- ✅ Configuration saved and applied
- ✅ Service status: unbound running (green)
- ✅ Test: DNS Lookup from pfSense works

**Total Time**: ~5 minutes

**Status**: ✅ DNS Resolver Configuration Complete
