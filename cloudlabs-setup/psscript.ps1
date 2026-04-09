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
        & $gitPath clone "https://github.com/KIRANGOWDAT/data-extraction-using-azure-content-understanding-final.git" "$labFilesPath\data-extraction-using-azure-content-understanding"
    } else {
        git clone "https://github.com/KIRANGOWDAT/data-extraction-using-azure-content-understanding-final.git" "$labFilesPath\data-extraction-using-azure-content-understanding"
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
#  DEPLOY AZURE INFRASTRUCTURE (Terraform)
# ============================================================================

function Get-LocationAbbreviation {
    param([string]$Location)
    $map = @{
        "westus"         = "wu";  "westus2"        = "wu2"; "westus3"        = "wu3"
        "eastus"         = "eu";  "eastus2"        = "eu2"
        "centralus"      = "cu";  "southcentralus" = "scu"; "northcentralus" = "ncu"
        "northeurope"    = "ne";  "westeurope"     = "we"
        "uksouth"        = "uks"; "ukwest"         = "ukw"
        "japaneast"      = "je";  "southeastasia"  = "sea"
        "australiaeast"  = "ae";  "canadacentral"  = "cc"
        "swedencentral"  = "sc";  "switzerlandnorth" = "swn"
    }
    if ($map.ContainsKey($Location)) { return $map[$Location] }
    return $Location.Substring(0, [Math]::Min(3, $Location.Length))
}

function Get-VMResourceGroup {
    Write-Log "Detecting resource group from Azure Instance Metadata Service..."
    try {
        $metadata = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" -Headers @{Metadata="true"} -TimeoutSec 5
        $rgName = $metadata.compute.resourceGroupName
        Write-Log "IMDS detected RG: $rgName"
        return $rgName
    } catch {
        Write-Log "WARNING: IMDS not available, falling back to az group list"
        $rgName = (az group list --query "[0].name" -o tsv)
        return $rgName
    }
}

function Deploy-AzureInfrastructure {
    Write-Log "Starting Azure infrastructure deployment..."

    # Login to Azure CLI
    Write-Log "Logging in to Azure CLI..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    az login -u $AzureUserName -p $AzurePassword --tenant $AzureTenantID 2>&1 | Out-File "C:\WindowsAzure\Logs\az-login.log" -Append
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERROR: Azure login failed. Terraform deployment skipped."
        return
    }
    az account set --subscription $AzureSubscriptionID
    Write-Log "Azure login successful."

    # Detect resource group and location (IMDS is reliable at scale)
    $rgName = Get-VMResourceGroup
    $location = (az group show --name $rgName --query "location" -o tsv)
    $locationAbbr = Get-LocationAbbreviation -Location $location
    Write-Log "Resource Group: $rgName | Location: $location ($locationAbbr)"

    # Create terraform.tfvars
    $iacPath = "C:\LabFiles\data-extraction-using-azure-content-understanding\iac"
    $tfvarsContent = @"
subscription_id              = "$AzureSubscriptionID"
existing_resource_group_name = "$rgName"
resource_group_location      = "$location"
resource_group_location_abbr = "$locationAbbr"
environment_name             = "dev"
usecase_name                 = "dataext$DeploymentID"
"@
    Set-Content -Path "$iacPath\terraform.tfvars" -Value $tfvarsContent -Force
    Write-Log "terraform.tfvars created."

    # Run Terraform
    Push-Location $iacPath
    Write-Log "Running terraform init..."
    terraform init -no-color 2>&1 | Out-File "C:\WindowsAzure\Logs\terraform-init.log" -Append
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERROR: terraform init failed. Check C:\WindowsAzure\Logs\terraform-init.log"
        Pop-Location
        return
    }
    Write-Log "terraform init completed."

    Write-Log "Running terraform apply (this may take 20-30 minutes)..."
    terraform apply -auto-approve -no-color 2>&1 | Out-File "C:\WindowsAzure\Logs\terraform-apply.log" -Append
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERROR: terraform apply failed. Check C:\WindowsAzure\Logs\terraform-apply.log"
        Pop-Location
        return
    }
    Pop-Location
    Write-Log "Terraform deployment completed successfully."
}

function Populate-KeyVaultSecrets {
    Write-Log "Populating Key Vault secrets..."

    $rgName = Get-VMResourceGroup
    $location = (az group show --name $rgName --query "location" -o tsv)
    $locationAbbr = Get-LocationAbbreviation -Location $location
    $prefix = "devdataext${DeploymentID}${locationAbbr}"
    $prefixLower = $prefix.ToLower()

    # Discover actual resource names from the resource group (handles naming patterns reliably)
    $kvName = (az keyvault list --resource-group $rgName --query "[0].name" -o tsv)
    $cosmosName = (az cosmosdb list --resource-group $rgName --query "[?contains(name,'cosmos0')].name" -o tsv)
    $openaiName = (az cognitiveservices account list --resource-group $rgName --query "[?kind=='OpenAI'].name" -o tsv)
    $aiServicesName = (az cognitiveservices account list --resource-group $rgName --query "[?kind=='AIServices'].name" -o tsv)

    Write-Log "Discovered resources — KV: $kvName | Cosmos: $cosmosName | OpenAI: $openaiName | AI Services: $aiServicesName"

    # Cosmos DB MongoDB connection string (contains & chars, must use file)
    if ($cosmosName) {
        $cosmosConn = az cosmosdb keys list --name $cosmosName --resource-group $rgName --type connection-strings --query "connectionStrings[0].connectionString" -o tsv
        if ($cosmosConn) {
            Set-Content -Path "$env:TEMP\cosmosconn.txt" -Value $cosmosConn -NoNewline
            az keyvault secret set --vault-name $kvName --name "cosmosdb-connection-string" --file "$env:TEMP\cosmosconn.txt" 2>&1 | Out-Null
            Remove-Item "$env:TEMP\cosmosconn.txt" -Force -ErrorAction SilentlyContinue
            Write-Log "Stored cosmosdb-connection-string in Key Vault."
        } else {
            Write-Log "WARNING: Could not retrieve Cosmos DB connection string."
        }
    } else {
        Write-Log "WARNING: Cosmos DB (MongoDB) resource not found."
    }

    # Azure OpenAI key
    if ($openaiName) {
        $openaiKey = az cognitiveservices account keys list --name $openaiName --resource-group $rgName --query "key1" -o tsv
        if ($openaiKey) {
            az keyvault secret set --vault-name $kvName --name "open-ai-key" --value $openaiKey 2>&1 | Out-Null
            Write-Log "Stored open-ai-key in Key Vault."
        } else {
            Write-Log "WARNING: Could not retrieve Azure OpenAI key."
        }
    } else {
        Write-Log "WARNING: Azure OpenAI resource not found."
    }

    # AI Services key
    if ($aiServicesName) {
        $aiKey = az cognitiveservices account keys list --name $aiServicesName --resource-group $rgName --query "key1" -o tsv
        if ($aiKey) {
            az keyvault secret set --vault-name $kvName --name "ai-foundry-key" --value $aiKey 2>&1 | Out-Null
            Write-Log "Stored ai-foundry-key in Key Vault."
        } else {
            Write-Log "WARNING: Could not retrieve AI Services key."
        }
    } else {
        Write-Log "WARNING: AI Services resource not found."
    }

    Write-Log "Key Vault secrets populated."
}

# ============================================================================
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

# Deploy Azure infrastructure (Terraform) and populate secrets
Deploy-AzureInfrastructure
Populate-KeyVaultSecrets

# User experience
Create-DesktopShortcuts

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
