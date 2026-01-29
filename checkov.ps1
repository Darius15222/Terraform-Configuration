<#
.SYNOPSIS
    Terraform security audit using Checkov with text file output

.PARAMETER OutputFile
    Path to output text file (default: terraform-security-audit.txt)

.PARAMETER SkipPlan
    Skip Terraform plan scan (only scan static code)

.EXAMPLE
    .\Invoke-CheckovAudit.ps1
    
.EXAMPLE
    .\Invoke-CheckovAudit.ps1 -OutputFile "audit-results.txt" -SkipPlan
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "terraform-security-audit.txt",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPlan
)

$ErrorActionPreference = "Stop"

# Initialize output file
$output = @()
$output += "=" * 80
$output += "TERRAFORM SECURITY AUDIT REPORT"
$output += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$output += "=" * 80
$output += ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan
$output += "PREREQUISITES CHECK"
$output += "-" * 80

try {
    $tfVersion = terraform version 2>&1 | Select-Object -First 1
    $output += "Terraform: $tfVersion"
    Write-Host "  Terraform: $tfVersion" -ForegroundColor Green
} catch {
    $output += "ERROR: Terraform not found"
    Write-Host "  ERROR: Terraform not found" -ForegroundColor Red
    $output | Out-File -FilePath $OutputFile -Encoding utf8
    exit 1
}

try {
    $checkovVersion = checkov --version 2>&1 | Select-Object -First 1
    $output += "Checkov: $checkovVersion"
    Write-Host "  Checkov: $checkovVersion" -ForegroundColor Green
} catch {
    $output += "ERROR: Checkov not found - Install with: pip install checkov"
    Write-Host "  ERROR: Checkov not found" -ForegroundColor Red
    $output | Out-File -FilePath $OutputFile -Encoding utf8
    exit 1
}

$output += ""

# Terraform init
Write-Host "Initializing Terraform..." -ForegroundColor Cyan
$output += "TERRAFORM INITIALIZATION"
$output += "-" * 80

terraform init -upgrade 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    $output += "Status: SUCCESS"
    Write-Host "  SUCCESS" -ForegroundColor Green
} else {
    $output += "Status: FAILED"
    Write-Host "  FAILED" -ForegroundColor Red
    $output | Out-File -FilePath $OutputFile -Encoding utf8
    exit 1
}
$output += ""

# Terraform validate
Write-Host "Validating Terraform configuration..." -ForegroundColor Cyan
$output += "TERRAFORM VALIDATION"
$output += "-" * 80

$validateOutput = terraform validate 2>&1
if ($LASTEXITCODE -eq 0) {
    $output += "Status: VALID"
    Write-Host "  VALID" -ForegroundColor Green
} else {
    $output += "Status: INVALID"
    $output += $validateOutput
    Write-Host "  INVALID" -ForegroundColor Red
    $output | Out-File -FilePath $OutputFile -Encoding utf8
    exit 1
}
$output += ""

# Scan static code
Write-Host "Scanning static Terraform code..." -ForegroundColor Cyan
$output += "=" * 80
$output += "STATIC CODE SECURITY SCAN"
$output += "=" * 80
$output += ""

$staticScan = checkov -d . --framework terraform --output cli 2>&1
$output += $staticScan
$output += ""
$output += "=" * 80
$output += ""

# Scan Terraform plan
if (-not $SkipPlan) {
    Write-Host "Creating Terraform plan..." -ForegroundColor Cyan
    $output += "TERRAFORM PLAN CREATION"
    $output += "-" * 80
    
    $planFile = Join-Path (Get-Location) "tfplan"
    $planJsonFile = Join-Path (Get-Location) "tfplan.json"
    
    terraform plan -out="$planFile" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0 -and (Test-Path $planFile)) {
        $output += "Status: SUCCESS"
        $output += "Plan file created: $planFile"
        Write-Host "  SUCCESS" -ForegroundColor Green
    } else {
        $output += "Status: FAILED - Plan file not created"
        Write-Host "  FAILED" -ForegroundColor Red
        $output | Out-File -FilePath $OutputFile -Encoding utf8
        exit 1
    }
    $output += ""
    
    Write-Host "Converting plan to JSON..." -ForegroundColor Cyan
    $jsonOutput = terraform show -json "$planFile" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $jsonOutput | Out-File -FilePath $planJsonFile -Encoding utf8
        $output += "Plan converted to JSON: $planJsonFile"
        Write-Host "  SUCCESS" -ForegroundColor Green
    } else {
        $output += "Status: FAILED - Could not convert plan to JSON"
        $output += $jsonOutput
        Write-Host "  FAILED" -ForegroundColor Red
        $output | Out-File -FilePath $OutputFile -Encoding utf8
        Remove-Item $planFile -Force -ErrorAction SilentlyContinue
        exit 1
    }
    $output += ""
    
    if (Test-Path $planJsonFile) {
        Write-Host "Scanning Terraform plan..." -ForegroundColor Cyan
        $output += "=" * 80
        $output += "TERRAFORM PLAN SECURITY SCAN"
        $output += "=" * 80
        $output += ""
        
        $planScan = checkov -f "$planJsonFile" --framework terraform_plan --output cli 2>&1
        $output += $planScan
        $output += ""
        $output += "=" * 80
        $output += ""
    } else {
        $output += "ERROR: Plan JSON file not found, skipping plan scan"
        Write-Host "  Plan JSON not found" -ForegroundColor Yellow
    }
    
    # Cleanup
    Remove-Item $planFile -Force -ErrorAction SilentlyContinue
    Remove-Item $planJsonFile -Force -ErrorAction SilentlyContinue
}

# Summary
$output += ""
$output += "AUDIT COMPLETED"
$output += "Report saved to: $OutputFile"
$output += "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$output += "=" * 80

# Save to file
$output | Out-File -FilePath $OutputFile -Encoding utf8

Write-Host ""
Write-Host "Audit complete! Report saved to: $OutputFile" -ForegroundColor Green
Write-Host ""

# Display summary
if ($staticScan) {
    $matchResult = $staticScan -match "Passed checks: (\d+), Failed checks: (\d+)"
    if ($matchResult -and $matches) {
        $passed = $matches[1]
        $failed = $matches[2]
        $total = [int]$passed + [int]$failed
        $score = if ($total -gt 0) { [math]::Round(([int]$passed / $total) * 100, 1) } else { 0 }
        
        Write-Host "Security Score: $score%" -ForegroundColor $(if ($score -ge 75) { "Green" } elseif ($score -ge 50) { "Yellow" } else { "Red" })
        Write-Host "Passed: $passed | Failed: $failed" -ForegroundColor Cyan
    } else {
        Write-Host "Summary statistics not available in scan output" -ForegroundColor Yellow
    }
} else {
    Write-Host "No scan results to display" -ForegroundColor Yellow
}

Write-Host ""