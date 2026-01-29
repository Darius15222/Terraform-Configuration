# 📦 FILES TO UPDATE IN YOUR PROJECT

This document lists all files that need to be updated in your cybersecurity lab project.

---

## ✅ CRITICAL FILES - MUST UPDATE

These files are **essential** for your lab to function:

### 1. **ubuntu-userdata.sh** - ⚠️ CRITICAL
**Status:** Currently empty → Must replace with automated script  
**Purpose:** Automatically deploys JuiceShop Docker container  
**What it does:**
- Installs Docker
- Deploys OWASP JuiceShop
- Adds logging and health checks
- Creates status file

**Action:** Replace entire file with new version

---

### 2. **kali-userdata.sh** - ⚠️ CRITICAL
**Status:** Currently empty → Must replace with automated script  
**Purpose:** Automatically deploys CyberChef Docker container  
**What it does:**
- Installs Docker
- Deploys CyberChef
- Creates desktop shortcuts
- Adds lab targets reference file
- Logging and health checks

**Action:** Replace entire file with new version

---

### 3. **pfsense-userdata.sh** - ⚠️ CRITICAL
**Status:** Currently empty → Must replace with configuration guide  
**Purpose:** Step-by-step manual configuration guide  
**What it contains:**
- DNS Resolver setup (5 min)
- DHCP Server configuration (10 min)
- SSL Certificate creation (5 min)
- Snort IDS installation (30 min)
- Troubleshooting guide

**Action:** Replace entire file with new version

---

### 4. **security.tf** - 🔧 IMPROVEMENT
**Status:** Functional but can be improved  
**Change:** Add explicit JuiceShop port rule  
**What changed:**
- Explicit ingress rule for port 3000 from Kali subnet
- Better documentation
- Clearer rule descriptions

**Action:** Replace entire file OR manually add explicit JuiceShop rule

---

### 5. **outputs.tf** - 🔧 IMPROVEMENT
**Status:** Basic → Enhanced with comprehensive info  
**What's new:**
- Lab services summary
- Verification steps
- Coursework scenarios
- Attack scenario guides
- Next steps guide
- Complete access instructions

**Action:** Replace entire file with comprehensive version

---

## 📚 NEW DOCUMENTATION FILES - HIGHLY RECOMMENDED

These files provide essential documentation:

### 6. **README.md** - 📄 NEW FILE
**Purpose:** Project overview and quick start guide  
**Contains:**
- Architecture diagram
- Feature list
- Quick start commands
- Documentation index
- Cost information
- Troubleshooting

**Action:** Create new file in project root

---

### 7. **DEPLOYMENT_GUIDE.md** - 📄 NEW FILE
**Purpose:** Complete step-by-step deployment guide  
**Contains:**
- Pre-deployment checklist
- Detailed deployment steps
- Verification procedures
- pfSense configuration
- Testing scenarios
- Troubleshooting

**Action:** Create new file (60+ pages of guidance)

---

### 8. **FINAL_TESTING_CHECKLIST.md** - 📄 NEW FILE
**Purpose:** Comprehensive verification checklist  
**Contains:**
- 100+ verification steps
- Infrastructure validation
- Service checks
- Attack scenario tests
- Documentation collection
- Success criteria

**Action:** Create new file

---

### 9. **SECURITY_AUDIT_REPORT.md** - 📄 NEW FILE
**Purpose:** Security posture analysis  
**Contains:**
- Checkov scan results (76% compliance)
- Security control analysis
- Failed checks justification
- Threat model
- Compliance statement

**Action:** Create new file

---

### 10. **AUDIT_SUMMARY.md** - 📄 NEW FILE
**Purpose:** Executive summary of complete audit  
**Contains:**
- Audit results
- Issues found and fixed
- Requirements fulfillment
- Final verdict
- Next steps

**Action:** Create new file

---

## 📋 EXISTING FILES - NO CHANGES NEEDED

These files are already correct and don't need updates:

✅ **providers.tf** - Already correct  
✅ **variables.tf** - Already correct  
✅ **locals.tf** - Already correct  
✅ **data.tf** - Already correct  
✅ **networking.tf** - Already correct  
✅ **routing.tf** - Already correct  
✅ **keys.tf** - Already correct  
✅ **instances.tf** - Already correct  
✅ **main.tf** - Already correct  
✅ **.gitignore** - Already correct  
✅ **terraform.tfvars.example** - Already correct  

---

## 🎯 UPDATE PRIORITY

### **PRIORITY 1: CRITICAL** (Must do before deployment)

1. **ubuntu-userdata.sh** - Lab won't work without JuiceShop
2. **kali-userdata.sh** - CyberChef needed for analysis
3. **pfsense-userdata.sh** - Configuration guide essential

**Time to update:** 5 minutes (copy/paste 3 files)

---

### **PRIORITY 2: HIGHLY RECOMMENDED** (Do after critical)

4. **outputs.tf** - Much better user experience
5. **security.tf** - Explicit JuiceShop port rule
6. **README.md** - Project overview
7. **DEPLOYMENT_GUIDE.md** - Essential for deployment

**Time to update:** 10 minutes (copy/paste files)

---

### **PRIORITY 3: NICE TO HAVE** (Can be added later)

8. **FINAL_TESTING_CHECKLIST.md** - Helpful for verification
9. **SECURITY_AUDIT_REPORT.md** - Good for coursework
10. **AUDIT_SUMMARY.md** - Complete overview

**Time to update:** 5 minutes (copy/paste files)

---

## 🚀 QUICK UPDATE PROCEDURE

### Option A: Update Everything (Recommended)

```bash
# 1. Navigate to your project directory
cd /path/to/your/project

# 2. Backup current files (optional but recommended)
mkdir backup_$(date +%Y%m%d)
cp *.sh *.tf *.md backup_$(date +%Y%m%d)/

# 3. Update critical files
# Copy ubuntu-userdata.sh, kali-userdata.sh, pfsense-userdata.sh

# 4. Update improved files
# Copy security.tf, outputs.tf

# 5. Add new documentation
# Copy README.md, DEPLOYMENT_GUIDE.md, etc.

# 6. Verify Terraform
terraform validate

# 7. Deploy
terraform apply
```

**Total time:** 20 minutes

---

### Option B: Minimal Update (Fastest)

```bash
# Update only the 3 critical user-data scripts
# Copy: ubuntu-userdata.sh, kali-userdata.sh, pfsense-userdata.sh

# Deploy
terraform apply
```

**Total time:** 5 minutes  
**Note:** Lab will work, but you'll miss improved outputs and documentation

---

### Option C: Gradual Update

```bash
# Day 1: Update critical files
# Copy: ubuntu-userdata.sh, kali-userdata.sh, pfsense-userdata.sh
terraform apply

# Day 2: Improve configuration
# Copy: security.tf, outputs.tf
terraform apply

# Day 3: Add documentation
# Copy: README.md, DEPLOYMENT_GUIDE.md, etc.
```

---

## 📝 FILE CHANGE SUMMARY

| File | Change Type | Impact | Priority |
|------|-------------|--------|----------|
| ubuntu-userdata.sh | Replace | CRITICAL | 1 |
| kali-userdata.sh | Replace | CRITICAL | 1 |
| pfsense-userdata.sh | Replace | CRITICAL | 1 |
| security.tf | Improve | Medium | 2 |
| outputs.tf | Enhance | Medium | 2 |
| README.md | Add | Low | 2 |
| DEPLOYMENT_GUIDE.md | Add | Low | 2 |
| FINAL_TESTING_CHECKLIST.md | Add | Low | 3 |
| SECURITY_AUDIT_REPORT.md | Add | Low | 3 |
| AUDIT_SUMMARY.md | Add | Low | 3 |

---

## ✅ VERIFICATION AFTER UPDATES

After updating files, verify:

```bash
# 1. Check Terraform syntax
terraform validate
# Expected: Success! The configuration is valid.

# 2. Check file exists
ls -la *-userdata.sh
# Should show 3 files with content

# 3. Check file permissions
ls -la *.tf
# All .tf files should be readable

# 4. Verify no syntax errors
terraform plan
# Should show plan without errors
```

---

## 🎓 WHAT EACH FILE ADDS TO YOUR COURSEWORK

### User-Data Scripts
✅ **Automated deployment** → Show Infrastructure-as-Code skills  
✅ **Docker containerization** → Demonstrate modern DevOps practices  
✅ **Service logging** → Prove deployment success

### Enhanced Outputs
✅ **Network diagrams** → Visual architecture documentation  
✅ **Access instructions** → Professional documentation  
✅ **Attack scenarios** → Coursework exercises ready-to-use

### Security Improvements
✅ **Explicit rules** → Better security documentation  
✅ **Defense-in-depth** → Show security architecture understanding

### Documentation Files
✅ **README** → Professional project presentation  
✅ **Deployment Guide** → Reproducible setup documentation  
✅ **Security Audit** → Demonstrate security awareness  
✅ **Testing Checklist** → Show thorough validation

---

## 🚨 IMPORTANT NOTES

### Before Updating

1. **Backup your current files** (especially if you made custom changes)
2. **Verify your admin_cidr in terraform.tfvars** is set correctly
3. **Check AWS credentials** are configured
4. **Review AMI IDs** in variables.tf match your region

### After Updating

1. **Run terraform validate** to check syntax
2. **Run terraform plan** to preview changes
3. **Wait 10 minutes after apply** for user-data scripts to complete
4. **Follow verification steps** in FINAL_TESTING_CHECKLIST.md
5. **Configure pfSense manually** following pfsense-userdata.sh guide

---

## 💡 TIPS

### If You're Short on Time
→ Update only the 3 user-data scripts (Priority 1)  
→ You can add documentation later

### If You Want Best Results
→ Update everything (all 10 files)  
→ Follow DEPLOYMENT_GUIDE.md step-by-step

### If You Have Questions
→ Read DEPLOYMENT_GUIDE.md first  
→ Check FINAL_TESTING_CHECKLIST.md for verification  
→ Review SECURITY_AUDIT_REPORT.md for security info

---

## 📞 QUICK REFERENCE

### Files You MUST Update
1. ubuntu-userdata.sh
2. kali-userdata.sh  
3. pfsense-userdata.sh

### Files You SHOULD Update
4. security.tf
5. outputs.tf
6. README.md
7. DEPLOYMENT_GUIDE.md

### Files That Are Optional
8. FINAL_TESTING_CHECKLIST.md
9. SECURITY_AUDIT_REPORT.md
10. AUDIT_SUMMARY.md

---

**Total files:** 10  
**Critical updates:** 3  
**Time required:** 5-20 minutes (depending on option chosen)  
**Result:** Fully functional cybersecurity lab ✅

---

Good luck with your updates! 🚀
