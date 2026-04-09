Param (
    [string]$AzureUserName,
    [string]$AzurePassword,
    [string]$AzureTenantID,
    [string]$AzureSubscriptionID,
    [string]$ODLID,
    [string]$DeploymentID,
    [string]$adminUsername,
    [string]$adminPassword,
    [string]$trainerUserName,
    [string]$trainerUserPassword
)

# ============================================================================
# Lab VM Setup Script — Data Extraction Using Azure Content Understanding
# CloudLabs-compatible: receives parameters from cloudlabsCommon variable
# ============================================================================

Start-Transcript -Path "C:\WindowsAzure\Logs\LabSetup.log" -Append -Force
$ErrorActionPreference = "SilentlyContinue"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Message"
}

Write-Log "========================================"
Write-Log "Starting Lab VM Setup..."
Write-Log "  DeploymentID : $DeploymentID"
Write-Log "  ODLID        : $ODLID"
Write-Log "  AdminUser     : $adminUsername"
Write-Log "========================================"

# ============================================================================
#  SYSTEM CONFIGURATION
# ============================================================================

function Disable-InternetExplorerESC {
    Write-Log "Disabling IE Enhanced Security Configuration..."
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey  = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $UserKey  -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
    Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
    Write-Log "IE ESC disabled."
}

function Disable-UserAccessControl {
    Write-Log "Disabling UAC..."
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
    Write-Log "UAC disabled."
}

function Enable-LongPaths {
    Write-Log "Enabling long paths..."
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1
    Write-Log "Long paths enabled."
}

function Set-WindowsFirewallRules {
    Write-Log "Configuring Windows Firewall for lab..."
    New-NetFirewallRule -DisplayName "Allow Azure Functions Port 7071" -Direction Inbound -LocalPort 7071 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Allow HTTPS 443" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    Write-Log "Firewall rules configured."
}

# ============================================================================
#  INSTALL CHOCOLATEY
# ============================================================================

function Install-Chocolatey {
    Write-Log "Installing Chocolatey..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    choco feature enable -n allowGlobalConfirmation
    Write-Log "Chocolatey installed."
}

# ============================================================================
#  INSTALL PREREQUISITES
# ============================================================================

function Install-Python {
    Write-Log "Installing Python 3.12..."
    choco install python312 --params "/InstallDir:C:\Python312" -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    & "C:\Python312\python.exe" -m pip install --upgrade pip
    Write-Log "Python 3.12 installed."
}

function Install-AzureCLI {
    Write-Log "Installing Azure CLI..."
    choco install azure-cli -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Log "Azure CLI installed."
}

function Install-Terraform {
    Write-Log "Installing Terraform..."
    choco install terraform -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Log "Terraform installed."
}

function Install-Git {
    Write-Log "Installing Git..."
    choco install git.install --params "/GitAndUnixToolsOnPath /NoShellIntegration" -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Log "Git installed."
}

function Install-NodeJS {
    Write-Log "Installing Node.js 18 LTS..."
    choco install nodejs-lts --version=18.20.4 -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Log "Node.js 18 installed."
}

function Install-AzureFunctionsCoreTools {
    Write-Log "Installing Azure Functions Core Tools v4..."
    choco install azure-functions-core-tools -y --params "'/x64'"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Log "Azure Functions Core Tools v4 installed."
}

function Install-VSCode {
    Write-Log "Installing Visual Studio Code..."
    choco install vscode -y --params "/NoDesktopIcon"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Start-Sleep -Seconds 10

    Write-Log "Installing VS Code extensions..."
    $codePath = "C:\Program Files\Microsoft VS Code\bin\code.cmd"
    if (Test-Path $codePath) {
        & $codePath --install-extension ms-python.python --force
        & $codePath --install-extension ms-azuretools.vscode-azurefunctions --force
        & $codePath --install-extension humao.rest-client --force
        & $codePath --install-extension ms-python.vscode-pylance --force
        & $codePath --install-extension hashicorp.terraform --force
        & $codePath --install-extension ms-vscode.azure-account --force
        & $codePath --install-extension tomoki1207.pdf --force
        Write-Log "VS Code extensions installed."
    } else {
        Write-Log "WARNING: VS Code not found at $codePath"
    }
}

function Install-DotNet {
    Write-Log "Installing .NET 8.0 SDK..."
    choco install dotnet-8.0-sdk -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Log ".NET 8.0 SDK installed."
}

function Install-WindowsTerminal {
    Write-Log "Installing Windows Terminal..."
    choco install microsoft-windows-terminal -y
    Write-Log "Windows Terminal installed."
}

# ============================================================================
#  CLONE REPOSITORY
# ============================================================================

function Clone-LabRepository {
    Write-Log "Cloning lab repository..."
    $labFilesPath = "C:\LabFiles"
    New-Item -ItemType Directory -Path $labFilesPath -Force | Out-Null

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    $gitPath = "C:\Program Files\Git\bin\git.exe"

    if (Test-Path $gitPath) {
        & $gitPath clone "https://github.com/KIRANGOWDA/data-extraction-using-azure-content-understanding-final.git" "$labFilesPath\data-extraction-using-azure-content-understanding"
    } else {
        git clone "https://github.com/KIRANGOWDA/data-extraction-using-azure-content-understanding-final.git" "$labFilesPath\data-extraction-using-azure-content-understanding"
    }

    Write-Log "Repository cloned to $labFilesPath."
}

# ============================================================================
#  DESKTOP SHORTCUTS
# ============================================================================

function Create-DesktopShortcuts {
    Write-Log "Creating desktop shortcuts..."
    $desktopPath = "C:\Users\$adminUsername\Desktop"
    if (-not (Test-Path $desktopPath)) { $desktopPath = "C:\Users\Public\Desktop" }

    $WshShell = New-Object -ComObject WScript.Shell

    # VS Code → lab folder
    $sc1 = $WshShell.CreateShortcut("$desktopPath\Visual Studio Code.lnk")
    $sc1.TargetPath = "C:\Program Files\Microsoft VS Code\Code.exe"
    $sc1.Arguments = "C:\LabFiles\data-extraction-using-azure-content-understanding"
    $sc1.WorkingDirectory = "C:\LabFiles\data-extraction-using-azure-content-understanding"
    $sc1.IconLocation = "C:\Program Files\Microsoft VS Code\Code.exe,0"
    $sc1.Save()

    # Lab Files folder
    $sc2 = $WshShell.CreateShortcut("$desktopPath\Lab Files.lnk")
    $sc2.TargetPath = "C:\LabFiles\data-extraction-using-azure-content-understanding"
    $sc2.Save()

    # Azure Portal
    $sc3 = $WshShell.CreateShortcut("$desktopPath\Azure Portal.url")
    $sc3.TargetPath = "https://portal.azure.com"
    $sc3.Save()

    Write-Log "Desktop shortcuts created."
}

# ============================================================================
#  SUPPRESS INTRO / WELCOME PAGES
# ============================================================================

function Configure-EdgeBrowser {
    Write-Log "Configuring Microsoft Edge..."
    $edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgeRegPath)) { New-Item -Path $edgeRegPath -Force | Out-Null }
    Set-ItemProperty -Path $edgeRegPath -Name "HideFirstRunExperience" -Value 1 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "DefaultBrowserSettingEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "StartupBoostEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "PersonalizationReportingEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "HubsSidebarEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "UserFeedbackAllowed" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "RestoreOnStartup" -Value 4 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "NewTabPageContentEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "PromotionalTabsEnabled" -Value 0 -Type DWord
    New-Item -Path "$edgeRegPath\RestoreOnStartupURLs" -Force | Out-Null
    Set-ItemProperty -Path "$edgeRegPath\RestoreOnStartupURLs" -Name "1" -Value "about:blank"
    Write-Log "Edge configured."
}

function Suppress-VSCodeIntroPages {
    Write-Log "Suppressing VS Code welcome pages..."
    $settingsJson = @'
{
    "workbench.startupEditor": "none",
    "workbench.tips.enabled": false,
    "workbench.welcomePage.walkthroughs.openOnInstall": false,
    "extensions.ignoreRecommendations": true,
    "update.showReleaseNotes": false,
    "telemetry.telemetryLevel": "off",
    "security.workspace.trust.enabled": false,
    "git.openRepositoryInParentFolders": "never"
}
'@
    $userDir = "C:\Users\$adminUsername\AppData\Roaming\Code\User"
    New-Item -ItemType Directory -Path $userDir -Force | Out-Null
    Set-Content -Path "$userDir\settings.json" -Value $settingsJson -Force

    $defaultDir = "C:\Users\Default\AppData\Roaming\Code\User"
    New-Item -ItemType Directory -Path $defaultDir -Force | Out-Null
    Set-Content -Path "$defaultDir\settings.json" -Value $settingsJson -Force
    Write-Log "VS Code intro pages suppressed."
}

function Suppress-WindowsIntroPages {
    Write-Log "Suppressing Windows welcome/intro experiences..."

    # Disable first-login animation ("Getting things ready for you...")
    $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $winlogonPath -Name "EnableFirstLogonAnimation" -Value 0 -Type DWord
    $systemPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    if (-not (Test-Path $systemPath)) { New-Item -Path $systemPath -Force | Out-Null }
    Set-ItemProperty -Path $systemPath -Name "EnableFirstLogonAnimation" -Value 0 -Type DWord

    # Disable OOBE privacy experience
    $oobePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
    if (-not (Test-Path $oobePath)) { New-Item -Path $oobePath -Force | Out-Null }
    Set-ItemProperty -Path $oobePath -Name "DisablePrivacyExperience" -Value 1 -Type DWord
    Set-ItemProperty -Path $oobePath -Name "PrivacyConsentStatus" -Value 1 -Type DWord
    Set-ItemProperty -Path $oobePath -Name "SkipMachineOOBE" -Value 1 -Type DWord
    Set-ItemProperty -Path $oobePath -Name "ProtectYourPC" -Value 3 -Type DWord

    # Disable Server Manager (if Windows Server)
    $smRegPath = "HKLM:\SOFTWARE\Microsoft\ServerManager"
    if (Test-Path $smRegPath) {
        Set-ItemProperty -Path $smRegPath -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Type DWord
    }

    # Disable "Let's finish setting up" nags
    $cloudContentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $cloudContentPath)) { New-Item -Path $cloudContentPath -Force | Out-Null }
    Set-ItemProperty -Path $cloudContentPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord
    Set-ItemProperty -Path $cloudContentPath -Name "DisableSoftLanding" -Value 1 -Type DWord
    Set-ItemProperty -Path $cloudContentPath -Name "DisableCloudOptimizedContent" -Value 1 -Type DWord

    # Disable Network Location Wizard popup
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force | Out-Null

    Write-Log "Windows intro pages suppressed."
}

function Set-BlackWallpaper {
    Write-Log "Setting black wallpaper..."
    $bmpPath = "C:\Windows\Web\Wallpaper\Black.bmp"
    $bmp = New-Object System.Drawing.Bitmap(1, 1)
    $bmp.SetPixel(0, 0, [System.Drawing.Color]::Black)
    $bmp.Save($bmpPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bmp.Dispose()

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name "DesktopImagePath" -Value $bmpPath
    Set-ItemProperty -Path $regPath -Name "DesktopImageUrl" -Value $bmpPath
    Set-ItemProperty -Path $regPath -Name "DesktopImageStatus" -Value 1 -Type DWord
    Write-Log "Black wallpaper set."
}

# ============================================================================
#  AUTO-LOGON
# ============================================================================

function Set-AutoLogon {
    param([string]$Username, [string]$Password)
    Write-Log "Configuring auto-logon for $Username..."
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1"
    Set-ItemProperty -Path $regPath -Name "DefaultUsername" -Value $Username
    Set-ItemProperty -Path $regPath -Name "DefaultPassword" -Value $Password
    Write-Log "Auto-logon configured."
}

# ============================================================================
#  VALIDATION SCRIPT
# ============================================================================

function Create-ValidationScript {
    Write-Log "Creating validation script on desktop..."
    $desktopPath = "C:\Users\$adminUsername\Desktop"
    if (-not (Test-Path $desktopPath)) { $desktopPath = "C:\Users\Public\Desktop" }

    $validationScript = @'
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Lab Environment Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$checks = @(
    @{ Name = "Python 3.12"; Command = { python --version 2>&1 } },
    @{ Name = "Azure CLI"; Command = { az version 2>&1 | ConvertFrom-Json | Select-Object -ExpandProperty 'azure-cli' } },
    @{ Name = "Terraform"; Command = { terraform version 2>&1 | Select-Object -First 1 } },
    @{ Name = "Git"; Command = { git --version 2>&1 } },
    @{ Name = "Node.js"; Command = { node --version 2>&1 } },
    @{ Name = "Azure Functions Core Tools"; Command = { func --version 2>&1 } },
    @{ Name = "VS Code"; Command = { code --version 2>&1 | Select-Object -First 1 } },
    @{ Name = "Lab Repository"; Command = { if (Test-Path "C:\LabFiles\data-extraction-using-azure-content-understanding") { "Present" } else { "NOT FOUND" } } }
)

foreach ($check in $checks) {
    try {
        $result = & $check.Command
        Write-Host "[PASS] $($check.Name): $result" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] $($check.Name): Not found or error" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Validation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Read-Host "Press Enter to close"
'@
    Set-Content -Path "$desktopPath\Validate-LabSetup.ps1" -Value $validationScript -Force
    Write-Log "Validation script created."
}

# ============================================================================
#  MAIN EXECUTION
# ============================================================================

# System configuration
Disable-InternetExplorerESC
Disable-UserAccessControl
Enable-LongPaths
Set-WindowsFirewallRules
Configure-EdgeBrowser

# Suppress all intro/welcome pages
Suppress-VSCodeIntroPages
Suppress-WindowsIntroPages
Set-BlackWallpaper

# Install package manager
Install-Chocolatey

# Install all prerequisites
Install-Git
Install-Python
Install-AzureCLI
Install-Terraform
Install-NodeJS
Install-AzureFunctionsCoreTools
Install-VSCode
Install-DotNet
Install-WindowsTerminal

# Clone lab repository
Clone-LabRepository

# User experience
Create-DesktopShortcuts
Create-ValidationScript

# Auto-logon for CloudLabs
if ($adminPassword -ne "") {
    Set-AutoLogon -Username $adminUsername -Password $adminPassword
}

Write-Log "========================================"
Write-Log "Lab VM Setup COMPLETE!"
Write-Log "========================================"

Stop-Transcript

# Signal completion
New-Item -ItemType File -Path "C:\WindowsAzure\Logs\LabSetupComplete.txt" -Value "Setup completed at $(Get-Date)" -Force
