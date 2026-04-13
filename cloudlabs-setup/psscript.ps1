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

Start-Transcript -Path "C:\WindowsAzure\Logs\LabSetup.log" -Append -Force
$ErrorActionPreference = "SilentlyContinue"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$ts] $Message"
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
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey  = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $UserKey  -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
    Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
}

function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
}

function Enable-LongPaths {
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1
}

function Set-WindowsFirewallRules {
    New-NetFirewallRule -DisplayName "Allow Azure Functions Port 7071" -Direction Inbound -LocalPort 7071 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Allow HTTPS 443" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
}

# ============================================================================
#  INSTALL TOOLS
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

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-Git {
    Write-Log "Installing Git..."
    choco install git.install --params "/GitAndUnixToolsOnPath /NoShellIntegration" -y
    Refresh-Path
    Write-Log "Git installed."
}

function Install-Python {
    Write-Log "Installing Python 3.12..."
    choco install python312 --params "/InstallDir:C:\Python312" -y
    Refresh-Path
    & "C:\Python312\python.exe" -m pip install --upgrade pip 2>&1 | Out-Null
    Write-Log "Python 3.12 installed."
}

function Install-AzureCLI {
    Write-Log "Installing Azure CLI..."
    choco install azure-cli -y
    Refresh-Path
    Write-Log "Azure CLI installed."
}

function Install-NodeJS {
    Write-Log "Installing Node.js 18 LTS..."
    choco install nodejs-lts --version=18.20.4 -y
    Refresh-Path
    Write-Log "Node.js 18 installed."
}

function Install-AzureFunctionsCoreTools {
    Write-Log "Installing Azure Functions Core Tools v4..."
    choco install azure-functions-core-tools -y --params "'/x64'"
    Refresh-Path
    Write-Log "Functions Core Tools installed."
}

function Install-VSCode {
    Write-Log "Installing Visual Studio Code..."
    choco install vscode -y --params "/NoDesktopIcon"
    Refresh-Path
    Start-Sleep -Seconds 10
    $codePath = "C:\Program Files\Microsoft VS Code\bin\code.cmd"
    if (Test-Path $codePath) {
        & $codePath --install-extension ms-python.python --force 2>&1 | Out-Null
        & $codePath --install-extension ms-azuretools.vscode-azurefunctions --force 2>&1 | Out-Null
        & $codePath --install-extension humao.rest-client --force 2>&1 | Out-Null
        & $codePath --install-extension ms-python.vscode-pylance --force 2>&1 | Out-Null
        & $codePath --install-extension ms-vscode.azure-account --force 2>&1 | Out-Null
        & $codePath --install-extension tomoki1207.pdf --force 2>&1 | Out-Null
        Write-Log "VS Code extensions installed."
    }
}

function Install-DotNet {
    Write-Log "Installing .NET 8.0 SDK..."
    choco install dotnet-8.0-sdk -y
    Refresh-Path
    Write-Log ".NET 8.0 installed."
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
    Refresh-Path
    $gitPath = "C:\Program Files\Git\bin\git.exe"
    if (Test-Path $gitPath) {
        & $gitPath clone "https://github.com/KIRANGOWDAT/data-extraction-using-azure-content-understanding-final.git" "$labFilesPath\data-extraction-using-azure-content-understanding" 2>&1
    } else {
        git clone "https://github.com/KIRANGOWDAT/data-extraction-using-azure-content-understanding-final.git" "$labFilesPath\data-extraction-using-azure-content-understanding" 2>&1
    }
    Write-Log "Repository cloned."
}

# ============================================================================
#  CONFIGURE LOCAL SETTINGS & PYTHON VENV
# ============================================================================

function Setup-PythonVenv {
    Write-Log "Setting up Python virtual environment..."
    $repoPath = "C:\LabFiles\data-extraction-using-azure-content-understanding"
    if (Test-Path $repoPath) {
        Push-Location $repoPath
        & "C:\Python312\python.exe" -m venv .venv 2>&1 | Out-Null
        & "$repoPath\.venv\Scripts\pip.exe" install --upgrade pip 2>&1 | Out-Null
        & "$repoPath\.venv\Scripts\pip.exe" install -r requirements.txt 2>&1 | Out-Null
        # Pre-create analyzer_cache to prevent func host restart during ingest
        New-Item -ItemType Directory -Path "$repoPath\src\analyzer_cache" -Force | Out-Null
        Pop-Location
        Write-Log "Python venv created and dependencies installed."
    } else {
        Write-Log "WARNING: Repository not found, skipping venv setup."
    }
}

function Fix-LocalSettings {
    Write-Log "Updating local.settings.json with storage connection string..."
    $settingsPath = "C:\LabFiles\data-extraction-using-azure-content-understanding\src\local.settings.json"
    if (Test-Path $settingsPath) {
        $content = Get-Content $settingsPath -Raw
        # Replace UseDevelopmentStorage=true with empty string (no Azurite on VM)
        $content = $content -replace '"UseDevelopmentStorage=true"', '""'
        Set-Content -Path $settingsPath -Value $content -Force
        Write-Log "local.settings.json updated."
    } else {
        Write-Log "WARNING: local.settings.json not found."
    }
}

function Configure-RDPPort443 {
    Write-Log "Configuring RDP to listen on port 443..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -Value 443 -Force
    netsh advfirewall firewall add rule name="RDP-443" dir=in action=allow protocol=tcp localport=443 2>$null
    Write-Log "RDP port set to 443. Will take effect after restart."
}

# ============================================================================
#  UI CONFIGURATION
# ============================================================================

function Configure-EdgeBrowser {
    $edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $edgeRegPath)) { New-Item -Path $edgeRegPath -Force | Out-Null }
    Set-ItemProperty -Path $edgeRegPath -Name "HideFirstRunExperience" -Value 1 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "DefaultBrowserSettingEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "RestoreOnStartup" -Value 4 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "NewTabPageContentEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "PromotionalTabsEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $edgeRegPath -Name "DefaultPopupsSetting" -Value 2 -Type DWord
    New-Item -Path "$edgeRegPath\RestoreOnStartupURLs" -Force | Out-Null
    Set-ItemProperty -Path "$edgeRegPath\RestoreOnStartupURLs" -Name "1" -Value "about:blank"
}

function Suppress-VSCodeIntroPages {
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
    foreach ($dir in @("C:\Users\$adminUsername\AppData\Roaming\Code\User", "C:\Users\Default\AppData\Roaming\Code\User")) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Set-Content -Path "$dir\settings.json" -Value $settingsJson -Force
    }
}

function Suppress-WindowsIntroPages {
    $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $winlogonPath -Name "EnableFirstLogonAnimation" -Value 0 -Type DWord
    $oobePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
    if (-not (Test-Path $oobePath)) { New-Item -Path $oobePath -Force | Out-Null }
    Set-ItemProperty -Path $oobePath -Name "DisablePrivacyExperience" -Value 1 -Type DWord
    Set-ItemProperty -Path $oobePath -Name "SkipMachineOOBE" -Value 1 -Type DWord
    Set-ItemProperty -Path $oobePath -Name "SkipUserOOBE" -Value 1 -Type DWord
    # Suppress user privacy settings page for all users
    $userOobePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OOBE"
    if (-not (Test-Path $userOobePath)) { New-Item -Path $userOobePath -Force | Out-Null }
    Set-ItemProperty -Path $userOobePath -Name "DisablePrivacyExperience" -Value 1 -Type DWord
    $smRegPath = "HKLM:\SOFTWARE\Microsoft\ServerManager"
    if (Test-Path $smRegPath) { Set-ItemProperty -Path $smRegPath -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Type DWord }
    $cloudContentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $cloudContentPath)) { New-Item -Path $cloudContentPath -Force | Out-Null }
    Set-ItemProperty -Path $cloudContentPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force | Out-Null
}

function Create-DesktopShortcuts {
    $desktopPath = "C:\Users\$adminUsername\Desktop"
    if (-not (Test-Path $desktopPath)) { $desktopPath = "C:\Users\Public\Desktop" }
    $WshShell = New-Object -ComObject WScript.Shell
    $sc1 = $WshShell.CreateShortcut("$desktopPath\Visual Studio Code.lnk")
    $sc1.TargetPath = "C:\Program Files\Microsoft VS Code\Code.exe"
    $sc1.Arguments = "C:\LabFiles\data-extraction-using-azure-content-understanding"
    $sc1.WorkingDirectory = "C:\LabFiles\data-extraction-using-azure-content-understanding"
    $sc1.IconLocation = "C:\Program Files\Microsoft VS Code\Code.exe,0"
    $sc1.Save()
    $sc2 = $WshShell.CreateShortcut("$desktopPath\Lab Files.lnk")
    $sc2.TargetPath = "C:\LabFiles\data-extraction-using-azure-content-understanding"
    $sc2.Save()
    $sc3 = $WshShell.CreateShortcut("$desktopPath\Azure Portal.url")
    $sc3.TargetPath = "https://portal.azure.com"
    $sc3.Save()
    $validateSrc = "C:\LabFiles\data-extraction-using-azure-content-understanding\cloudlabs-setup\Validate-LabSetup.ps1"
    if (Test-Path $validateSrc) {
        Copy-Item -Path $validateSrc -Destination "$desktopPath\Validate-LabSetup.ps1" -Force
    }
    Write-Log "Desktop shortcuts created."
}

function Set-AutoLogon {
    param([string]$Username, [string]$Password)
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1"
    Set-ItemProperty -Path $regPath -Name "DefaultUsername" -Value $Username
    Set-ItemProperty -Path $regPath -Name "DefaultPassword" -Value $Password
}

function Set-BlackDesktopBackground {
    Write-Log "Setting desktop wallpaper to plain black..."

    # Create a 1x1 black BMP image (v1 proven approach)
    $wallpaperPath = "C:\Windows\Web\Wallpaper\black.bmp"
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap(1, 1)
    $bmp.SetPixel(0, 0, [System.Drawing.Color]::Black)
    $bmp.Save($wallpaperPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bmp.Dispose()

    # Set wallpaper via PersonalizationCSP (critical for Azure VMs)
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name "DesktopImagePath" -Value $wallpaperPath -Type String
    Set-ItemProperty -Path $regPath -Name "DesktopImageUrl" -Value $wallpaperPath -Type String
    Set-ItemProperty -Path $regPath -Name "DesktopImageStatus" -Value 1 -Type DWord

    # Set for default user profile (new logons)
    $defaultRegPath = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop"
    Set-ItemProperty -Path $defaultRegPath -Name "WallPaper" -Value $wallpaperPath -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $defaultRegPath -Name "WallpaperStyle" -Value "2" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $defaultRegPath -Name "TileWallpaper" -Value "0" -ErrorAction SilentlyContinue

    # Set for current user (SYSTEM during script execution)
    $currentRegPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $currentRegPath -Name "WallPaper" -Value $wallpaperPath -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $currentRegPath -Name "WallpaperStyle" -Value "2" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $currentRegPath -Name "TileWallpaper" -Value "0" -ErrorAction SilentlyContinue

    # Set for admin user profile if SID is resolable
    try {
        $adminSid = (New-Object System.Security.Principal.NTAccount($adminUsername)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $adminRegPath = "Registry::HKEY_USERS\$adminSid\Control Panel\Desktop"
        if (Test-Path $adminRegPath) {
            Set-ItemProperty -Path $adminRegPath -Name "WallPaper" -Value $wallpaperPath -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $adminRegPath -Name "WallpaperStyle" -Value "2" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $adminRegPath -Name "TileWallpaper" -Value "0" -ErrorAction SilentlyContinue
        }
    } catch { Write-Log "Could not resolve admin SID for wallpaper, using fallback." }

    # Fallback: also load NTUSER.DAT for the admin user
    $ntUserDat = "C:\Users\$adminUsername\NTUSER.DAT"
    if (Test-Path $ntUserDat) {
        try {
            reg load "HKU\TempUser" $ntUserDat 2>$null
            reg add "HKU\TempUser\Control Panel\Desktop" /v WallPaper /t REG_SZ /d $wallpaperPath /f 2>$null
            reg add "HKU\TempUser\Control Panel\Desktop" /v WallPaperStyle /t REG_SZ /d "2" /f 2>$null
            reg add "HKU\TempUser\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d "0" /f 2>$null
            reg add "HKU\TempUser\Control Panel\Colors" /v Background /t REG_SZ /d "0 0 0" /f 2>$null
            reg unload "HKU\TempUser" 2>$null
        } catch { Write-Log "Could not load user hive for wallpaper: $_" }
    }

    # Also set via Default user profile so any new logon inherits black background
    $defaultNtUser = "C:\Users\Default\NTUSER.DAT"
    if (Test-Path $defaultNtUser) {
        try {
            reg load "HKU\DefaultUser" $defaultNtUser 2>$null
            reg add "HKU\DefaultUser\Control Panel\Desktop" /v WallPaper /t REG_SZ /d $wallpaperPath /f 2>$null
            reg add "HKU\DefaultUser\Control Panel\Desktop" /v WallPaperStyle /t REG_SZ /d "2" /f 2>$null
            reg add "HKU\DefaultUser\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d "0" /f 2>$null
            reg add "HKU\DefaultUser\Control Panel\Colors" /v Background /t REG_SZ /d "0 0 0" /f 2>$null
            reg unload "HKU\DefaultUser" 2>$null
        } catch { Write-Log "Could not set default profile wallpaper: $_" }
    }

    # Remove any Windows Spotlight / theme wallpaper policies
    $personalizePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    if (-not (Test-Path $personalizePath)) { New-Item -Path $personalizePath -Force | Out-Null }
    Set-ItemProperty -Path $personalizePath -Name "LockScreenImage" -Value "" -Force
    Set-ItemProperty -Path $personalizePath -Name "NoChangingLockScreen" -Value 1 -Type DWord -Force

    Write-Log "Desktop background set to solid black."
}

# ============================================================================
#  MAIN EXECUTION
# ============================================================================

Write-Log "Phase 1: System configuration..."
Disable-InternetExplorerESC
Disable-UserAccessControl
Enable-LongPaths
Set-WindowsFirewallRules
Configure-EdgeBrowser
Suppress-VSCodeIntroPages
Suppress-WindowsIntroPages

Write-Log "Phase 2: Installing tools..."
Install-Chocolatey
Install-Git
Install-Python
Install-AzureCLI
Install-NodeJS
Install-AzureFunctionsCoreTools
Install-VSCode
Install-DotNet
Install-WindowsTerminal

Write-Log "Phase 3: Cloning repository..."
Clone-LabRepository

Write-Log "Phase 4: Setting up application environment..."
Setup-PythonVenv
Fix-LocalSettings
Configure-RDPPort443

Write-Log "Phase 5: Configuring user experience..."
Create-DesktopShortcuts
Set-BlackDesktopBackground
if ($adminPassword -ne "") {
    Set-AutoLogon -Username $adminUsername -Password $adminPassword
}

Write-Log "========================================"
Write-Log "Lab VM Setup COMPLETE!"
Write-Log "========================================"

Stop-Transcript

$completionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
New-Item -ItemType File -Path "C:\WindowsAzure\Logs\LabSetupComplete.txt" -Value "Setup completed at $completionTime" -Force
