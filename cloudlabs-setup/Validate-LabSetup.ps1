# Validate-LabSetup.ps1
# Lab Environment Validation Script
# Checks that all required tools and prerequisites are installed

$ErrorActionPreference = "SilentlyContinue"

function Write-Check {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    if ($Pass) {
        Write-Host "  [PASS] " -ForegroundColor Green -NoNewline
        Write-Host "$Name - $Detail"
    } else {
        Write-Host "  [FAIL] " -ForegroundColor Red -NoNewline
        Write-Host "$Name - $Detail"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab Environment Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allPass = $true

# Python
$pyVer = & C:\Python312\python.exe --version 2>&1
if ($pyVer -match "Python 3\.1[2-9]") {
    Write-Check "Python" $true $pyVer
} else {
    $pyVer2 = python --version 2>&1
    if ($pyVer2 -match "Python 3\.1[2-9]") {
        Write-Check "Python" $true $pyVer2
    } else {
        Write-Check "Python" $false "3.12 or later required"
        $allPass = $false
    }
}

# Azure CLI
$azVer = az version -o tsv 2>&1 | Select-Object -First 1
if ($azVer -match "\d+\.\d+") {
    Write-Check "Azure CLI" $true "v$azVer"
} else {
    Write-Check "Azure CLI" $false "Not found"
    $allPass = $false
}

# Terraform
$tfVer = terraform --version 2>&1 | Select-Object -First 1
if ($tfVer -match "Terraform v(\d+\.\d+\.\d+)") {
    Write-Check "Terraform" $true $tfVer
} else {
    Write-Check "Terraform" $false "1.5.0 or later required"
    $allPass = $false
}

# Azure Functions Core Tools
$funcVer = func --version 2>&1
if ($funcVer -match "^4\.") {
    Write-Check "Azure Functions Core Tools" $true "v$funcVer"
} else {
    Write-Check "Azure Functions Core Tools" $false "v4.x required"
    $allPass = $false
}

# Git
$gitVer = git --version 2>&1
if ($gitVer -match "git version") {
    Write-Check "Git" $true $gitVer
} else {
    Write-Check "Git" $false "Not found"
    $allPass = $false
}

# Node.js
$nodeVer = node --version 2>&1
if ($nodeVer -match "^v1[8-9]|^v[2-9]\d") {
    Write-Check "Node.js" $true $nodeVer
} else {
    Write-Check "Node.js" $false "18.x or later required"
    $allPass = $false
}

# VS Code
if (Test-Path "C:\Program Files\Microsoft VS Code\Code.exe") {
    $codeVer = & "C:\Program Files\Microsoft VS Code\bin\code.cmd" --version 2>&1 | Select-Object -First 1
    Write-Check "Visual Studio Code" $true "v$codeVer"
} else {
    Write-Check "Visual Studio Code" $false "Not found"
    $allPass = $false
}

# Lab Repository
if (Test-Path "C:\LabFiles\data-extraction-using-azure-content-understanding\src") {
    Write-Check "Lab Repository" $true "Present at C:\LabFiles"
} else {
    Write-Check "Lab Repository" $false "Not found at C:\LabFiles"
    $allPass = $false
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($allPass) {
    Write-Host "  All checks PASSED!" -ForegroundColor Green
} else {
    Write-Host "  Some checks FAILED." -ForegroundColor Red
    Write-Host "  Contact your lab administrator." -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
