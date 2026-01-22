# Cyber Lab - Production-Grade Terraform Infrastructure

This Terraform configuration deploys a cybersecurity lab environment on AWS with pfSense firewall, Kali Linux, and Ubuntu Server.

## 🎯 What Changed (Improvements from Original Code)

### 1. **Security Hardening** ✅
- **Before**: SSH and HTTPS open to the entire internet (`0.0.0.0/0`)
- **After**: Restricted to your specific admin IP via `admin_cidr` variable
- **Why**: Follows the Principle of Least Privilege - reduces attack surface

### 2. **Flexibility & Reusability** ✅
- **Before**: Hard-coded values scattered across files (region, CIDRs, instance types)
- **After**: Centralized in `variables.tf` - change once, apply everywhere
- **Why**: Easy to deploy to different regions or customize for different use cases

### 3. **Resilience** ✅
- **Before**: Hard-coded availability zone (`eu-central-1a`) could fail if zone is unavailable
- **After**: Dynamic AZ selection via `data.aws_availability_zones.available`
- **Why**: Automatic failover to available zones in any region

### 4. **Maintainability** ✅
- **Before**: Tags defined individually for each resource
- **After**: Common tags in `locals.tf` merged with resource-specific tags
- **Why**: Consistent tagging for billing, compliance, and resource tracking

### 5. **IP Management** ✅
- **Before**: Hard-coded IP addresses (e.g., `10.0.2.100`)
- **After**: Calculated using `cidrhost()` function based on subnet variables
- **Why**: Automatically adjust IPs when changing CIDR ranges

---

## 📁 File Structure

```
.
├── providers.tf              # AWS provider configuration
├── variables.tf              # Input variables (NEW)
├── locals.tf                 # Computed values and common tags (NEW)
├── data.tf                   # Data sources (AMIs, AZs)
├── networking.tf             # VPC, subnets, network interfaces
├── security.tf               # Security groups
├── routing.tf                # Route tables
├── keys.tf                   # SSH key generation
├── instances.tf              # EC2 instances
├── outputs.tf                # Output values
├── pfsense-userdata.sh       # pfSense bootstrap script
├── .gitignore                # Git ignore rules
└── terraform.tfvars.example  # Example variables file (NEW)
```

---

## 🚀 Quick Start

### Prerequisites
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- An AWS account with appropriate permissions

### Step 1: Configure Your Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars and set your admin IP
# Find your public IP: https://whatismyip.com
nano terraform.tfvars
```

**Example `terraform.tfvars`:**
```hcl
admin_cidr = "203.0.113.45/32"  # Replace with YOUR IP
```

### Step 2: Initialize and Deploy

```bash
# Initialize Terraform (downloads providers)
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

### Step 3: Access Your Lab

After deployment, Terraform outputs:
```
pfsense_public_ip = "54.93.x.x"
pfsense_web_interface = "https://54.93.x.x"
ssh_key_path = "./lab-key.pem"
```

**Access pfSense Web Interface:**
```
https://<pfsense_public_ip>
Default credentials: admin / pfsense
```

**SSH to Kali (via pfSense jump host):**
```bash
ssh -i lab-key.pem -J admin@<pfsense_public_ip> kali@10.0.2.100
```

---

## 🔧 Configuration Options

### Network Customization

Change IP ranges in `terraform.tfvars`:
```hcl
vpc_cidr = "172.16.0.0/16"

subnet_cidrs = {
  wan    = "172.16.1.0/24"
  kali   = "172.16.2.0/24"
  ubuntu = "172.16.3.0/24"
}
```

### Instance Sizing

Adjust performance/cost:
```hcl
instance_types = {
  pfsense = "t3.medium"  # More CPU for firewall
  kali    = "t3.large"   # More resources for pentesting
  ubuntu  = "t3.micro"   # Keep target small
}
```

### Region Change

Deploy to a different region:
```hcl
aws_region = "us-east-1"
```

---

## 📊 Cost Estimation

**Monthly estimate (us-east-1 pricing, all instances running 24/7):**
- pfSense (t3.small): ~$15/month
- Kali (t3.small): ~$15/month
- Ubuntu (t3.micro): ~$7.50/month
- **Total: ~$37.50/month**

**Cost savings tip:** Stop instances when not in use:
```bash
aws ec2 stop-instances --instance-ids <instance-id>
```

---

## 🔒 Security Best Practices

1. **NEVER commit `terraform.tfvars` or `lab-key.pem`** (both are gitignored)
2. **Change pfSense default password immediately** after first login
3. **Use a `/32` CIDR for `admin_cidr`** (single IP, not a range)
4. **Enable AWS CloudTrail** for audit logging
5. **Use AWS Budget Alerts** to avoid unexpected costs

---

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

⚠️ **Warning:** This deletes everything, including the SSH key file.

---

## 🛠️ Troubleshooting

### Error: "No available zones"
- **Cause:** AWS doesn't have capacity in the region
- **Fix:** Change `aws_region` in `terraform.tfvars`

### Error: "InvalidAMIID.NotFound"
- **Cause:** AMI not available in selected region
- **Fix:** pfSense/Kali may not be available in all regions. Try `eu-central-1` or `us-east-1`

### Can't SSH to instances
- **Cause 1:** `admin_cidr` doesn't match your public IP
  - **Fix:** Update `terraform.tfvars` and run `terraform apply`
- **Cause 2:** pfSense not configured yet
  - **Fix:** Wait 5-10 minutes for instance initialization

---

## 📚 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [pfSense Documentation](https://docs.netgate.com/pfsense/en/latest/)
- [Kali Linux Tools](https://www.kali.org/tools/)

---

## 📝 License

This project is provided as-is for educational purposes.

---

## 🤝 Contributing

Improvements welcome! Follow these guidelines:
1. Test changes in a separate AWS account
2. Update documentation for any new variables
3. Maintain consistent tagging and naming conventions
