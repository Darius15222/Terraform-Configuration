# pfSense SSL Certificate Configuration Guide

## Overview

This guide covers creating a self-signed SSL certificate for pfSense web interface.

**Purpose**: Secure HTTPS access to pfSense with your own custom certificate

**Time Required**: 5 minutes

**Prerequisites**: pfSense web interface accessible

---

## Why Self-Signed Certificate?

### What You Need for Let's Encrypt:
- ❌ Public domain name (example.com)
- ❌ DNS records pointing to your IP
- ❌ HTTP/DNS validation access
- ❌ Time and money ($10+/year for domain)

### What You Have:
- ✅ Public IP address (Elastic IP)
- ✅ pfSense running
- ✅ No domain name

**Conclusion**: Self-signed certificate is your only option without a domain name.

---

## Self-Signed vs Trusted Certificate

### Self-Signed Certificate:
- ✅ Works with IP addresses
- ✅ Free
- ✅ 5 minutes setup
- ✅ Encrypted HTTPS connection
- ⚠️ Browser shows warning (expected, not a problem)
- ✅ Acceptable for labs/internal use

### Trusted Certificate (Let's Encrypt):
- ❌ Requires domain name
- ❌ Requires DNS configuration
- ❌ Extra setup time
- ✅ No browser warning
- ✅ Required for public websites

---

## Part 1: Create Certificate Authority (CA)

**What is a CA**: The entity that signs certificates (like a passport office)

**Why needed**: pfSense requires a CA to sign your server certificate

### Step 1: Navigate to Certificate Authorities

1. Log into pfSense web interface
2. Go to: **System → Cert Manager**
3. Click **Authorities** tab at the top

### Step 2: Create New CA

1. Click **Add** button (or **Create/Edit CA**)

### Step 3: Configure CA

**Descriptive name**:
- Enter: `pfSense Internal CA`

**Method**:
- Select: **Create an internal Certificate Authority**

**Key type**:
- Select: **RSA** (default)

**Key length**:
- Select: **2048** (default, adequate security)

**Digest Algorithm**:
- Select: **sha256** (default, secure)

**Lifetime (days)**:
- Enter: `3650` (10 years)

**Common Name**:
- Enter: `internal-ca`

**Country Code**:
- Select: **RO** (Romania)

**State or Province**:
- Enter: `Sibiu`

**City**:
- Enter: `Sibiu`

**Organization**:
- Enter: `CyberLab`

**Organizational Unit**:
- Leave blank (optional field)

### Step 4: Save CA

1. Click **Save** button at the bottom
2. CA is now created and appears in the list

**What you created**: Internal Certificate Authority that can sign certificates for your lab

---

## Part 2: Create Server Certificate

**What is a server certificate**: The actual certificate used for HTTPS (like a passport)

### Step 1: Navigate to Certificates

1. Still in **System → Cert Manager**
2. Click **Certificates** tab at the top

### Step 2: Add New Certificate

1. Click **Add/Sign** button

### Step 3: Configure Certificate

**Method**:
- Select: **Create an internal Certificate**

**Descriptive name**:
- Enter: `pfSense Lab Certificate`

**Certificate authority**:
- Select: **pfSense Internal CA** (the CA you just created)

**Key type**:
- Select: **RSA** (default)

**Key length**:
- Select: **2048** (default)

**Digest Algorithm**:
- Select: **sha256** (default)

**Lifetime (days)**:
- Enter: `3650` (10 years - won't expire during coursework)

**Common Name**:
- Enter: `cyberlab.local`

**Why this name**: Matches your internal domain name from DHCP configuration

**Country Code**:
- Select: **RO**

**State or Province**:
- Enter: `Sibiu`

**City**:
- Enter: `Sibiu`

**Organization**:
- Enter: `CyberLab`

**Organizational Unit**:
- Leave blank (optional)

**Certificate Type**:
- Select: **Server Certificate**

**Why Server Certificate**: pfSense is the server, your browser is the client

**Alternative Names**:
- Leave blank or ignore (optional field)

### Step 4: Save Certificate

1. Scroll to bottom
2. Click **Save** button
3. Certificate is created and appears in the Certificates list

**What you created**: Server certificate signed by your CA that pfSense can use for HTTPS

---

## Part 3: Apply Certificate to pfSense Web Interface

**What this does**: Tells pfSense to use your new certificate instead of the default one

### Step 1: Navigate to Admin Access Settings

1. Go to: **System → Advanced**
2. Click **Admin Access** tab at the top

### Step 2: Select Your Certificate

1. Find the **SSL/TLS Certificate** dropdown
2. Current selection: Probably shows default pfSense certificate
3. Change to: **pfSense Lab Certificate** (your certificate)

### Step 3: Save and Apply

1. Scroll to bottom of page
2. Click **Save** button
3. pfSense may reload the page

### Step 4: Verify Certificate Applied

1. Close your browser completely
2. Reopen browser
3. Navigate to: `https://<PFSENSE_PUBLIC_IP>`
4. Click the ❌ **Not secure** warning in address bar
5. Click **Certificate** or **View certificate**

**Expected certificate details**:
```
Issued to: cyberlab.local
Issued by: pfSense Internal CA
Valid from: [today's date]
Valid until: [today's date + 10 years]
Organization: CyberLab
Location: Sibiu, Sibiu, RO
```

**If you see these details**: ✅ Certificate is working correctly!

---

## Understanding the Browser Warning

### Why Browser Shows "Not Secure"

**Your browser sees**:
```
Certificate issued by: pfSense Internal CA
Browser's trusted CAs: Let's Encrypt, DigiCert, GoDaddy, etc.
Verdict: "I don't recognize pfSense Internal CA" → Show warning
```

**This is EXPECTED and NORMAL for self-signed certificates**

---

### What the Warning Means

**Browser is saying**:
- "I don't trust this certificate"
- "It's not signed by a CA I recognize"
- "I can't verify the identity of this server"

**Browser is NOT saying**:
- "Connection is not encrypted" (it IS encrypted!)
- "Your data is at risk" (data is protected!)
- "This is dangerous" (it's safe for internal use!)

---

### Connection IS Encrypted ✅

**Before certificate**:
- URL: `http://18.159.181.174` (no HTTPS)
- No encryption
- Data sent in plain text

**After certificate**:
- URL: `https://18.159.181.174` (HTTPS enabled)
- TLS encryption active
- Data encrypted in transit
- Browser warning: Expected for self-signed

---

### Is This Acceptable?

**For educational labs**: ✅ YES
- Self-signed certificates are standard practice
- Browser warnings are expected
- Connection is still encrypted
- Fulfills coursework requirements
- Professional network administrators use self-signed certs for internal infrastructure

**For public websites**: ❌ NO
- Need trusted CA (Let's Encrypt)
- Need domain name
- Users should not see warnings

---

## Verification Checklist

### Verify CA Created:
1. Go to: **System → Cert Manager → Authorities**
2. Should see: **pfSense Internal CA** in the list
3. Status: Valid ✅

### Verify Certificate Created:
1. Go to: **System → Cert Manager → Certificates**
2. Should see: **pfSense Lab Certificate** in the list
3. Status: Valid ✅
4. Issuer: pfSense Internal CA

### Verify Certificate Applied:
1. Go to: **System → Advanced → Admin Access**
2. **SSL/TLS Certificate** dropdown shows: pfSense Lab Certificate
3. Browser URL shows: `https://` (not `http://`)

### Verify Browser Shows Your Certificate:
1. Click ❌ Not secure in address bar
2. View certificate details
3. Verify:
   - Issued to: cyberlab.local
   - Issued by: pfSense Internal CA
   - Organization: CyberLab
   - Validity: 10 years

**If all checks pass**: ✅ Certificate configuration complete!

---

## Certificate Hierarchy Explained

### How It Works:

```
┌─────────────────────────────┐
│  pfSense Internal CA        │ ← You created this (Certificate Authority)
│  (The "Passport Office")    │
│  - Can sign other certs     │
│  - Not trusted by browsers  │
└──────────────┬──────────────┘
               │
               │ Signs
               ▼
┌─────────────────────────────┐
│  pfSense Lab Certificate    │ ← You created this (Server Certificate)
│  (The "Passport")           │
│  - Used for HTTPS           │
│  - Signed by Internal CA    │
│  - Shows browser warning    │
└─────────────────────────────┘
```

### Compare with Trusted Certificate:

```
┌─────────────────────────────┐
│  Let's Encrypt CA           │ ← Trusted by all browsers
│  (Well-known authority)     │
│  - Trusted worldwide        │
│  - Requires domain name     │
└──────────────┬──────────────┘
               │
               │ Signs
               ▼
┌─────────────────────────────┐
│  Your Website Certificate   │ ← Trusted certificate
│  (example.com)              │
│  - Used for HTTPS           │
│  - No browser warning       │
│  - Requires domain name     │
└─────────────────────────────┘
```

---

## What Certificate Provides

### Security Benefits:

**Encryption** ✅:
- All traffic between browser and pfSense is encrypted
- TLS 1.2 or 1.3 protocol
- AES encryption for data
- Cannot be intercepted by third parties

**Data Integrity** ✅:
- Data cannot be modified in transit
- Hash verification ensures no tampering
- Man-in-the-middle attacks prevented

**Server Identity** ⚠️:
- Certificate proves server identity
- BUT: Browser doesn't trust your CA
- Acceptable for internal/lab use

---

### What It Doesn't Provide:

**Trusted Identity** ❌:
- Browser doesn't recognize your CA
- Still shows "Not secure" warning
- Fine for labs, not for public sites

**Automatic Trust** ❌:
- Users must manually accept certificate
- Each browser shows warning
- Normal behavior for self-signed certs

---

## Troubleshooting

### Issue: Can't Create Certificate - "Certificate authority is required"

**Cause**: No CA exists yet

**Solution**: 
1. Go to **Authorities** tab
2. Create CA first (Part 1 of this guide)
3. Return to **Certificates** tab
4. CA will now appear in dropdown

---

### Issue: Certificate Not Appearing in Admin Access Dropdown

**Cause**: Certificate not created or wrong type

**Solution**:
1. Verify certificate exists: **System → Cert Manager → Certificates**
2. Verify **Certificate Type**: Must be "Server Certificate"
3. If wrong type: Delete and recreate with correct type

---

### Issue: Browser Still Shows Default Certificate

**Cause**: Browser cached old certificate

**Solution**:
1. Close browser completely (all windows)
2. Clear browser cache/SSL state
3. Reopen browser
4. Navigate to pfSense URL
5. Force refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

---

### Issue: "Not Secure" Warning Won't Go Away

**Cause**: This is EXPECTED behavior for self-signed certificates

**Solution**: No action needed - this is normal and acceptable

**Explanation**:
- Self-signed certificates always show this warning
- Only trusted CA certificates (Let's Encrypt, etc.) remove the warning
- To remove warning, you would need:
  - Public domain name
  - Let's Encrypt certificate
  - DNS configuration
  - Not worth it for educational lab

---

### Issue: Certificate Expired

**Cause**: Set lifetime too short (e.g., 365 days instead of 3650)

**Solution**:
1. Create new certificate with lifetime: 3650 days (10 years)
2. Apply new certificate to Admin Access
3. Old certificate can be deleted from Cert Manager

---

## Certificate Technical Details

### Cryptographic Specifications:

**Algorithm**: RSA (Rivest–Shamir–Adleman)
- Public key cryptography
- Industry standard
- Widely supported

**Key Length**: 2048 bits
- Adequate security for most use cases
- Balance between security and performance
- Can use 4096 bits for higher security (slower)

**Digest Algorithm**: SHA-256
- Cryptographic hash function
- Secure against collision attacks
- Modern standard (SHA-1 is deprecated)

**Validity Period**: 3650 days (10 years)
- Long enough for entire coursework
- Won't expire unexpectedly
- Production certs typically: 90-365 days

---

### Certificate Structure:

**Subject**:
```
CN=cyberlab.local
O=CyberLab
L=Sibiu
ST=Sibiu
C=RO
```

**Issuer**:
```
CN=internal-ca
O=CyberLab
L=Sibiu
ST=Sibiu
C=RO
```

**Extensions**:
- Key Usage: Digital Signature, Key Encipherment
- Extended Key Usage: TLS Web Server Authentication
- Basic Constraints: CA:FALSE (this is not a CA)

---

## Coursework Documentation

### Evidence to Collect:

1. **Certificate Creation**:
   - Screenshot: System → Cert Manager → Authorities (showing CA)
   - Screenshot: System → Cert Manager → Certificates (showing certificate)

2. **Certificate Applied**:
   - Screenshot: System → Advanced → Admin Access (showing certificate selected)

3. **Certificate Details**:
   - Screenshot: Browser certificate viewer showing:
     - Issued to: cyberlab.local
     - Issued by: pfSense Internal CA
     - Validity period: 10 years
     - Organization: CyberLab

4. **HTTPS Connection**:
   - Screenshot: Browser address bar showing `https://`
   - Screenshot: "Not secure" warning (shows you understand self-signed behavior)

---

## Comparison: Self-Signed vs Let's Encrypt

| Feature | Self-Signed | Let's Encrypt |
|---------|-------------|---------------|
| Cost | Free | Free |
| Setup Time | 5 minutes | 30+ minutes |
| Requirements | None | Domain name + DNS |
| Browser Warning | Yes | No |
| Encryption | Yes | Yes |
| Automatic Renewal | Manual | Automatic (90 days) |
| Trust Level | Internal only | Public trust |
| Use Case | Labs, internal | Public websites |
| Coursework Valid | ✅ Yes | ✅ Yes (if you have domain) |

---

## Alternative: Import Your CA to Browser (Optional)

**Advanced**: You can make your browser trust your CA (removes warning)

**Not recommended for this lab**:
- Time consuming
- Must import CA to every device/browser
- Overkill for temporary educational environment
- Warning is acceptable and expected

**If you want to try**:
1. Export CA certificate: System → Cert Manager → Authorities → Export
2. Import to browser trusted root CAs
3. Browser will now trust certificates signed by your CA

---

## Configuration Summary

### What You Created:

**Certificate Authority**:
- Name: pfSense Internal CA
- Type: Internal CA
- Purpose: Signs server certificates
- Validity: 10 years
- Status: Active ✅

**Server Certificate**:
- Name: pfSense Lab Certificate
- Issued by: pfSense Internal CA
- Common Name: cyberlab.local
- Purpose: HTTPS for pfSense web interface
- Validity: 10 years
- Status: Applied to web interface ✅

**Result**:
- ✅ HTTPS enabled on pfSense
- ✅ Encrypted connection active
- ✅ Custom certificate with your details
- ⚠️ Browser warning (expected for self-signed)
- ✅ Coursework requirement fulfilled

---

## Time Breakdown

**Part 1: Create CA**: 2 minutes
- Navigate to Authorities
- Fill in CA details
- Save

**Part 2: Create Certificate**: 2 minutes
- Navigate to Certificates
- Select CA from dropdown
- Fill in certificate details
- Save

**Part 3: Apply Certificate**: 1 minute
- Navigate to Admin Access
- Select certificate
- Save

**Total Time**: 5 minutes

---

## Completion Checklist

- ✅ Certificate Authority created (pfSense Internal CA)
- ✅ Server certificate created (pfSense Lab Certificate)
- ✅ Certificate applied to pfSense web interface
- ✅ Browser shows `https://` in URL
- ✅ Certificate details show your information
- ✅ Connection is encrypted (TLS active)
- ⚠️ Browser shows "Not secure" warning (expected and acceptable)
- ✅ Screenshots collected for coursework

**Status**: ✅ SSL Certificate Configuration Complete

---

## Next Steps

After SSL certificate configuration:

1. **Optional: Configure Snort IDS** (30 minutes)
   - Install Snort package
   - Configure intrusion detection
   - Generate alerts for attack scenarios

2. **Test the Lab**:
   - Verify JuiceShop accessible from Kali
   - Perform SQL injection attacks
   - Capture traffic with Wireshark
   - Collect coursework evidence

3. **Document Everything**:
   - Take screenshots
   - Export Wireshark captures
   - Collect Snort alerts
   - Prepare coursework submission

---

## Summary

You successfully configured a self-signed SSL certificate for pfSense:

✅ **Encryption**: HTTPS connection active  
✅ **Custom Certificate**: With your organization details  
✅ **10-Year Validity**: Won't expire during coursework  
✅ **Professional Setup**: Demonstrates certificate management skills  
⚠️ **Browser Warning**: Expected behavior (not a problem)

**Your lab now has secure, encrypted access to the firewall management interface.**
