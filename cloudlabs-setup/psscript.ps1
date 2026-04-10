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

function Install-Terraform {
    Write-Log "Installing Terraform..."
    choco install terraform -y
    Refresh-Path
    Write-Log "Terraform installed."
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
#  DEPLOY AZURE RESOURCES VIA MANAGED IDENTITY
# ============================================================================

function Deploy-AzureResources {
    Write-Log "========================================"
    Write-Log "Starting Azure resource deployment..."
    Write-Log "========================================"

    Refresh-Path

    # --- Login with VM managed identity ---
    Write-Log "Logging in with managed identity..."
    $maxRetries = 10
    for ($i = 0; $i -lt $maxRetries; $i++) {
        az login --identity 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Managed identity login succeeded."
            break
        }
        Write-Log "Waiting for managed identity... (attempt $($i+1)/$maxRetries)"
        Start-Sleep -Seconds 30
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERROR: Failed to login with managed identity after $maxRetries attempts."
        return
    }

    # --- Determine RG and subscription from IMDS ---
    $metadata = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-12-13"
    $subscriptionId = $metadata.compute.subscriptionId
    $resourceGroupName = $metadata.compute.resourceGroupName
    az account set --subscription $subscriptionId 2>&1 | Out-Null

    Write-Log "Subscription: $subscriptionId"
    Write-Log "Resource Group: $resourceGroupName"

    # --- Naming ---
    $location = "swedencentral"
    $prefix = "devde$DeploymentID"
    $hashInput = "/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName$DeploymentID"
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hashBytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($hashInput.ToLower()))
    $alphabet = "abcdefghijklmnopqrstuvwxyz234567"
    $uniqueSuffix = ""
    for ($j = 0; $j -lt 5; $j++) { $uniqueSuffix += $alphabet[$hashBytes[$j] % $alphabet.Length] }

    $cosmosMongoName = "${prefix}cosmos"
    $cosmosSqlName   = "${prefix}cosmoskb"
    $openaiName      = "aoai${prefix}"
    $aiServicesName  = "${prefix}ais"
    $kvName          = "${prefix}kv"
    $storageName     = "${prefix}sa${uniqueSuffix}"
    $logName         = "${prefix}-log"
    $appInsName      = "${prefix}appins"
    $aspName         = "${prefix}func${uniqueSuffix}asp"
    $funcAppName     = "${prefix}func${uniqueSuffix}"
    $funcMiName      = "${funcAppName}-identity"
    $aiHubName       = "${prefix}aml"
    $aiProjectName   = "${prefix}-rag-project"
    $rg = $resourceGroupName

    Write-Log "Prefix: $prefix | Suffix: $uniqueSuffix"

    # --- 1. User Assigned Managed Identity ---
    Write-Log "Creating User Assigned Managed Identity..."
    az identity create -g $rg -n $funcMiName -l $location -o none 2>&1
    $funcMiId = az identity show -g $rg -n $funcMiName --query id -o tsv 2>&1
    $funcMiClientId = az identity show -g $rg -n $funcMiName --query clientId -o tsv 2>&1
    $funcMiPrincipalId = az identity show -g $rg -n $funcMiName --query principalId -o tsv 2>&1
    Write-Log "MI created: $funcMiName (principalId: $funcMiPrincipalId)"

    # --- 2. Cosmos DB MongoDB ---
    Write-Log "Creating Cosmos DB MongoDB account..."
    az cosmosdb create -n $cosmosMongoName -g $rg --kind MongoDB --server-version "4.2" --locations regionName=$location failoverPriority=0 isZoneRedundant=false --default-consistency-level Session --enable-automatic-failover false -o none 2>&1
    Write-Log "Creating MongoDB database and collections..."
    az cosmosdb mongodb database create -a $cosmosMongoName -g $rg -n "data-extraction-db" -o none 2>&1
    az cosmosdb mongodb collection create -a $cosmosMongoName -g $rg -d "data-extraction-db" -n "Documents" --shard "domain" -o none 2>&1
    az cosmosdb mongodb collection create -a $cosmosMongoName -g $rg -d "data-extraction-db" -n "Configurations" --shard "domain" -o none 2>&1
    Write-Log "Cosmos MongoDB done."

    # --- 3. Cosmos DB SQL ---
    Write-Log "Creating Cosmos DB SQL account..."
    az cosmosdb create -n $cosmosSqlName -g $rg --kind GlobalDocumentDB --locations regionName=$location failoverPriority=0 isZoneRedundant=false --default-consistency-level Session -o none 2>&1
    Write-Log "Creating SQL database and container..."
    az cosmosdb sql database create -a $cosmosSqlName -g $rg -n "knowledge-base-db" -o none 2>&1

    # MultiHash partition key requires REST API
    $containerBody = @{
        properties = @{
            resource = @{
                id = "chat-history"
                partitionKey = @{
                    paths = @("/user_id", "/domain")
                    kind = "MultiHash"
                    version = 2
                }
            }
        }
    } | ConvertTo-Json -Depth 5 -Compress
    az rest --method PUT --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.DocumentDB/databaseAccounts/$cosmosSqlName/sqlDatabases/knowledge-base-db/containers/chat-history?api-version=2024-05-15" --body $containerBody -o none 2>&1
    Write-Log "Cosmos SQL done."

    # --- 4. Azure OpenAI ---
    Write-Log "Creating Azure OpenAI account..."
    az cognitiveservices account create -n $openaiName -g $rg -l $location --kind OpenAI --sku S0 --custom-domain $openaiName --yes -o none 2>&1
    Write-Log "Deploying gpt-4o model..."
    az cognitiveservices account deployment create -n $openaiName -g $rg --deployment-name "gpt-4o" --model-name "gpt-4o" --model-version "2024-08-06" --model-format OpenAI --sku-capacity 10 --sku-name "GlobalStandard" -o none 2>&1
    Write-Log "OpenAI done."

    # --- 5. AI Services ---
    Write-Log "Creating AI Services account..."
    az cognitiveservices account create -n $aiServicesName -g $rg -l $location --kind CognitiveServices --sku S0 --custom-domain $aiServicesName --yes -o none 2>&1
    Write-Log "AI Services done."

    # --- 6. Key Vault ---
    Write-Log "Creating Key Vault..."
    az keyvault create -n $kvName -g $rg -l $location --enable-rbac-authorization true --retention-days 7 --enabled-for-template-deployment true -o none 2>&1

    # Assign Key Vault Secrets Officer to VM MI for writing secrets
    $vmPrincipalId = (Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-12-13").compute.resourceId
    $vmObjectId = az vm show --ids $vmPrincipalId --query "identity.principalId" -o tsv 2>&1
    az role assignment create --assignee-object-id $vmObjectId --assignee-principal-type ServicePrincipal --role "Key Vault Secrets Officer" --scope $(az keyvault show -n $kvName -g $rg --query id -o tsv) -o none 2>&1
    Start-Sleep -Seconds 15

    # Set secrets
    $cosmosConnStr = az cosmosdb keys list -n $cosmosMongoName -g $rg --type connection-strings --query "connectionStrings[0].connectionString" -o tsv 2>&1
    $openaiKey = az cognitiveservices account keys list -n $openaiName -g $rg --query "key1" -o tsv 2>&1
    $aiServicesKey = az cognitiveservices account keys list -n $aiServicesName -g $rg --query "key1" -o tsv 2>&1
    az keyvault secret set --vault-name $kvName -n "cosmosdb-connection-string" --value "$cosmosConnStr" -o none 2>&1
    az keyvault secret set --vault-name $kvName -n "open-ai-key" --value "$openaiKey" -o none 2>&1
    az keyvault secret set --vault-name $kvName -n "ai-foundry-key" --value "$aiServicesKey" -o none 2>&1
    Write-Log "Key Vault + secrets done."

    # --- 7. Storage Account ---
    Write-Log "Creating Storage Account..."
    az storage account create -n $storageName -g $rg -l $location --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false -o none 2>&1
    $storageKey = az storage account keys list -n $storageName -g $rg --query "[0].value" -o tsv 2>&1
    az storage container create -n "processed" --account-name $storageName --account-key $storageKey -o none 2>&1
    Write-Log "Storage done."

    # --- 8. Log Analytics + App Insights ---
    Write-Log "Creating Log Analytics & App Insights..."
    az monitor log-analytics workspace create -g $rg -n $logName -l $location --retention-time 30 -o none 2>&1
    $logId = az monitor log-analytics workspace show -g $rg -n $logName --query id -o tsv 2>&1
    az monitor app-insights component create -g $rg -a $appInsName -l $location --workspace $logId -o none 2>&1
    Write-Log "Log Analytics + App Insights done."

    # --- 9. Function App ---
    Write-Log "Creating Function App..."
    az functionapp create -g $rg -n $funcAppName --consumption-plan-location $location --runtime python --runtime-version 3.12 --functions-version 4 --storage-account $storageName --os-type Linux -o none 2>&1
    az functionapp identity assign -g $rg -n $funcAppName --identities $funcMiId -o none 2>&1

    $appInsKey = az monitor app-insights component show -g $rg -a $appInsName --query instrumentationKey -o tsv 2>&1
    $appInsConnStr = az monitor app-insights component show -g $rg -a $appInsName --query connectionString -o tsv 2>&1
    $cosmosMongoEndpoint = az cosmosdb show -n $cosmosMongoName -g $rg --query "documentEndpoint" -o tsv 2>&1
    $cosmosSqlEndpoint = az cosmosdb show -n $cosmosSqlName -g $rg --query "documentEndpoint" -o tsv 2>&1
    $openaiEndpoint = az cognitiveservices account show -n $openaiName -g $rg --query "properties.endpoint" -o tsv 2>&1
    $aiServicesEndpoint = az cognitiveservices account show -n $aiServicesName -g $rg --query "properties.endpoint" -o tsv 2>&1

    az functionapp config appsettings set -g $rg -n $funcAppName -o none --settings `
        "FUNCTIONS_EXTENSION_VERSION=~4" `
        "FUNCTIONS_WORKER_RUNTIME=python" `
        "APPINSIGHTS_INSTRUMENTATIONKEY=$appInsKey" `
        "APPLICATIONINSIGHTS_CONNECTION_STRING=$appInsConnStr" `
        "ENVIRONMENT=dev" `
        "APP_CLIENT_ID=$funcMiClientId" `
        "APP_TENANT_ID=$AzureTenantID" `
        "KEY_VAULT_URI=https://${kvName}.vault.azure.net/" `
        "COSMOS_DB_URI=$cosmosMongoEndpoint" `
        "COSMOS_DB_NAME=data-extraction-db" `
        "COSMOS_SQL_URI=$cosmosSqlEndpoint" `
        "COSMOS_SQL_DB_NAME=knowledge-base-db" `
        "AOAI_ENDPOINT=$openaiEndpoint" `
        "AOAI_MODEL_DEPLOYMENT_NAME=gpt-4o" `
        "AI_SERVICES_ENDPOINT=$aiServicesEndpoint" `
        "STORAGE_ACCOUNT_NAME=$storageName" `
        "STORAGE_CONTAINER_NAME=processed" 2>&1
    Write-Log "Function App done."

    # --- 10. Role Assignments for Function App MI ---
    Write-Log "Creating role assignments..."
    $kvId = az keyvault show -n $kvName -g $rg --query id -o tsv 2>&1
    $aisId = az cognitiveservices account show -n $aiServicesName -g $rg --query id -o tsv 2>&1
    $storageId = az storage account show -n $storageName -g $rg --query id -o tsv 2>&1
    $cosmosMongoId = az cosmosdb show -n $cosmosMongoName -g $rg --query id -o tsv 2>&1
    $cosmosSqlId = az cosmosdb show -n $cosmosSqlName -g $rg --query id -o tsv 2>&1

    az role assignment create --assignee-object-id $funcMiPrincipalId --assignee-principal-type ServicePrincipal --role "Key Vault Secrets User" --scope $kvId -o none 2>&1
    az role assignment create --assignee-object-id $funcMiPrincipalId --assignee-principal-type ServicePrincipal --role "Cognitive Services User" --scope $aisId -o none 2>&1
    az role assignment create --assignee-object-id $funcMiPrincipalId --assignee-principal-type ServicePrincipal --role "Storage Blob Data Contributor" --scope $storageId -o none 2>&1
    az role assignment create --assignee-object-id $funcMiPrincipalId --assignee-principal-type ServicePrincipal --role "DocumentDB Account Contributor" --scope $cosmosMongoId -o none 2>&1
    az role assignment create --assignee-object-id $funcMiPrincipalId --assignee-principal-type ServicePrincipal --role "DocumentDB Account Contributor" --scope $cosmosSqlId -o none 2>&1

    # Cosmos SQL data-plane role
    az cosmosdb sql role assignment create --account-name $cosmosSqlName --resource-group $rg --principal-id $funcMiPrincipalId --role-definition-id "00000000-0000-0000-0000-000000000002" --scope "/" -o none 2>&1
    Write-Log "Role assignments done."

    # --- 11. AI Foundry Hub + Project + Connections ---
    Write-Log "Creating AI Foundry Hub..."
    $appInsId = az monitor app-insights component show -g $rg -a $appInsName --query id -o tsv 2>&1

    $hubBody = @{
        location = $location
        kind = "hub"
        identity = @{ type = "SystemAssigned" }
        properties = @{
            friendlyName = $aiHubName
            storageAccount = $storageId
            keyVault = $kvId
            applicationInsights = $appInsId
            publicNetworkAccess = "Enabled"
        }
    } | ConvertTo-Json -Depth 5 -Compress
    az rest --method PUT --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.MachineLearningServices/workspaces/${aiHubName}?api-version=2024-04-01" --body $hubBody -o none 2>&1
    # Wait for hub to be ready
    Start-Sleep -Seconds 30
    Write-Log "AI Hub created."

    Write-Log "Creating AI Project..."
    $hubId = "/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.MachineLearningServices/workspaces/$aiHubName"
    $projBody = @{
        location = $location
        kind = "project"
        identity = @{ type = "SystemAssigned" }
        properties = @{
            friendlyName = $aiProjectName
            hubResourceId = $hubId
            publicNetworkAccess = "Enabled"
        }
    } | ConvertTo-Json -Depth 5 -Compress
    az rest --method PUT --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.MachineLearningServices/workspaces/${aiProjectName}?api-version=2024-04-01" --body $projBody -o none 2>&1
    Write-Log "AI Project created."

    # Connections
    Write-Log "Creating AI Hub connections..."
    $openaiResourceId = az cognitiveservices account show -n $openaiName -g $rg --query id -o tsv 2>&1
    $aisResourceId = $aisId

    $openaiConnBody = @{
        properties = @{
            category = "AzureOpenAI"
            target = $openaiEndpoint
            authType = "AAD"
            metadata = @{ ApiType = "Azure"; ResourceId = $openaiResourceId }
        }
    } | ConvertTo-Json -Depth 5 -Compress
    az rest --method PUT --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.MachineLearningServices/workspaces/$aiHubName/connections/openai-connection?api-version=2024-04-01" --body $openaiConnBody -o none 2>&1

    $aisAoaiConnBody = @{
        properties = @{
            category = "AzureOpenAI"
            target = $aiServicesEndpoint
            authType = "AAD"
            metadata = @{ ApiType = "Azure"; ResourceId = $aisResourceId }
        }
    } | ConvertTo-Json -Depth 5 -Compress
    az rest --method PUT --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.MachineLearningServices/workspaces/$aiHubName/connections/aiservices-connection_aoai?api-version=2024-04-01" --body $aisAoaiConnBody -o none 2>&1

    $aisConnBody = @{
        properties = @{
            category = "AIServices"
            target = $aiServicesEndpoint
            authType = "AAD"
            metadata = @{ ApiType = "Azure"; ResourceId = $aisResourceId }
        }
    } | ConvertTo-Json -Depth 5 -Compress
    az rest --method PUT --url "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.MachineLearningServices/workspaces/$aiHubName/connections/aiservices-connection?api-version=2024-04-01" --body $aisConnBody -o none 2>&1
    Write-Log "AI Foundry connections done."

    Write-Log "========================================"
    Write-Log "Azure resource deployment COMPLETE!"
    Write-Log "========================================"
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
Install-Terraform
Install-VSCode
Install-DotNet
Install-WindowsTerminal

Write-Log "Phase 3: Cloning repository..."
Clone-LabRepository

Write-Log "Phase 4: Deploying Azure resources..."
Deploy-AzureResources

Write-Log "Phase 5: Configuring user experience..."
Create-DesktopShortcuts
if ($adminPassword -ne "") {
    Set-AutoLogon -Username $adminUsername -Password $adminPassword
}

Write-Log "========================================"
Write-Log "Lab VM Setup COMPLETE!"
Write-Log "========================================"

Stop-Transcript

$completionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
New-Item -ItemType File -Path "C:\WindowsAzure\Logs\LabSetupComplete.txt" -Value "Setup completed at $completionTime" -Force
