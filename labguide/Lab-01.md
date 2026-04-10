# Lab 01: Explore Azure Resources and Configure Content Understanding

### Estimated Duration: 60 Minutes

## Overview

In this lab, you will explore the Azure resources that were automatically deployed for the document extraction pipeline. You will navigate to Azure AI Foundry to understand the Content Understanding project, verify the Azure OpenAI gpt-4o model deployment, and then set up the Python application locally by configuring it with the correct Azure resource endpoints.

## Objectives

After completing this lab, you will have:

- Explored the pre-deployed Azure resources in your resource group
- Navigated Azure AI Foundry and the Content Understanding project
- Verified the Azure OpenAI gpt-4o model deployment
- Set up the Python virtual environment
- Configured the application with Azure resource endpoints and keys

### Task 1: Explore pre-deployed Azure resources

In this task, you will navigate to the Azure Portal and explore the resources that were automatically deployed during VM provisioning.

1. Open the **Azure Portal** using the desktop shortcut or navigate to [https://portal.azure.com](https://portal.azure.com). Sign in if prompted.

1. In the Azure Portal, click on **Resource groups** in the left navigation menu, then click on your resource group **<inject key="Resource Group Name" enableCopy="false" />**.

1. Review the list of deployed resources. You should see the following:

   | Resource Type | Name Pattern | Purpose |
   |---|---|---|
   | Key Vault | **devde<inject key="DeploymentID" enableCopy="false" />kv** | Stores API keys and connection strings |
   | Azure Cosmos DB (MongoDB) | **devde<inject key="DeploymentID" enableCopy="false" />cosmos** | Stores extraction configs and extracted data |
   | Azure Cosmos DB (SQL) | **devde<inject key="DeploymentID" enableCopy="false" />cosmoskb** | Stores chat history |
   | Azure OpenAI | **aoaidevde<inject key="DeploymentID" enableCopy="false" />** | Hosts the gpt-4o model |
   | AI Services | **devde<inject key="DeploymentID" enableCopy="false" />ais** | Azure Content Understanding |
   | Storage Account | **devde<inject key="DeploymentID" enableCopy="false" />sa******* (random suffix) | Stores processed documents |
   | Function App | **devde<inject key="DeploymentID" enableCopy="false" />func****** | Hosts the extraction API |
   | Application Insights | **devde<inject key="DeploymentID" enableCopy="false" />appins** | Monitoring and tracing |

1. Click on the **Key Vault** resource (**devde<inject key="DeploymentID" enableCopy="false" />kv**). In the left menu, click **Objects** > **Secrets**. Verify that three secrets are pre-populated:

   - **cosmosdb-connection-string** — Cosmos DB MongoDB connection string
   - **open-ai-key** — Azure OpenAI API key
   - **ai-foundry-key** — AI Services subscription key

   >**Note:** These secrets were automatically stored by the VM setup script. The application reads them at runtime via Key Vault references, so API keys are never hardcoded in configuration files.

### Task 2: Navigate to Azure AI Foundry and Content Understanding

In this task, you will explore Azure AI Foundry to understand the Content Understanding project that powers document extraction.

1. In your resource group, click on the **AI Services** resource (**devde<inject key="DeploymentID" enableCopy="false" />ais**).

1. In the left menu, expand **Resource Management** and click on **Keys and Endpoint**. Note the following — you will need these when configuring the application:

   - **Endpoint** URL (e.g., https://devde<inject key="DeploymentID" enableCopy="false" />ais.cognitiveservices.azure.com/)
   - **KEY 1** (already stored in Key Vault as **ai-foundry-key**)

   >**Note:** Azure AI Content Understanding is a capability within Azure AI Services. It uses custom **analyzers** to extract structured fields from documents. The analyzers are created programmatically by the application when you upload an extraction configuration.

1. Go back to your resource group and click on the **AI Services** resource again. On the overview page, click **Go to Azure AI Foundry** to open the AI Foundry portal.

1. In Azure AI Foundry, you should see the project **devde<inject key="DeploymentID" enableCopy="false" />-rag-project** in the left navigation. Click on it.

1. Note the **Project ID** displayed on the project overview page. Copy this value — you will need it when configuring the application in Task 5.

   >**What is a Content Understanding project?** A project in AI Foundry provides a workspace where Content Understanding analyzers are organized. When the application creates an analyzer, it tags it with this project ID so it appears under this project.

### Task 3: Explore the Azure OpenAI gpt-4o deployment

In this task, you will verify the Azure OpenAI model deployment that powers the natural language query interface.

1. Go back to the Azure Portal. In your resource group, click on the **Azure OpenAI** resource (**aoaidevde<inject key="DeploymentID" enableCopy="false" />**).

1. On the overview page, click **Go to Azure AI Foundry** (or **Go to Azure OpenAI Studio**).

1. Navigate to **Deployments** in the left menu. Verify that the **gpt-4o** model is deployed with:

   - **Model:** gpt-4o
   - **Version:** 2024-08-06
   - **Deployment type:** Standard

1. Click on the **gpt-4o** deployment. Note the **Target URI** (endpoint) — it should look like:

   ```
   https://aoaidevde<inject key="DeploymentID" enableCopy="false" />.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2025-04-01-preview
   ```

   >**How does this fit the architecture?** When a user queries extracted data, the application uses **Semantic Kernel** to send the query + extracted document data to this gpt-4o deployment. The LLM formulates a response using the extracted fields as context.

### Task 4: Set up the Python virtual environment

In this task, you will set up the Python virtual environment required to run the application locally.

1. On the desktop, double-click the **Visual Studio Code** shortcut to open the project.

1. In VS Code, open a new terminal by clicking **Terminal** > **New Terminal** from the menu bar (or press **Ctrl+`**).

1. Verify you are in the project root directory:

   ```
   cd C:\LabFiles\data-extraction-using-azure-content-understanding
   ```

1. Create a Python virtual environment:

   ```
   python -m venv .venv
   ```

1. Activate the virtual environment:

   ```
   .venv\Scripts\activate
   ```

   You should see `(.venv)` appear at the beginning of your terminal prompt.

1. Install the project dependencies:

   ```
   pip install -r requirements.txt
   ```

   >**Note:** This installs all required Python packages including `azure-functions`, `azure-identity`, `azure-keyvault-secrets`, `azure-cosmos`, `semantic-kernel`, and other dependencies. This may take 2—3 minutes.

### Task 5: Configure the application

In this task, you will configure the application with the correct Azure resource endpoints and keys so it can connect to Content Understanding, Azure OpenAI, Cosmos DB, and Key Vault.

1. In VS Code Explorer, navigate to **src** > **resources** and open **app_config.yaml**.

1. Scroll to the `local:` section. This is the configuration used when running the Function App locally. Update the following values:

   | Setting | Value |
   |---------|-------|
   | `key_vault_uri` | `https://devde<inject key="DeploymentID" enableCopy="false" />kv.vault.azure.net/` |
   | `tenant_id` | Your Azure Tenant ID (find it in Azure Portal > Azure Active Directory > Overview) |
   | `llm.endpoint.value` | `https://aoaidevde<inject key="DeploymentID" enableCopy="false" />.openai.azure.com/openai/deployments/gpt-4o` |
   | `content_understanding.endpoint.value` | `https://devde<inject key="DeploymentID" enableCopy="false" />ais.cognitiveservices.azure.com/` |
   | `content_understanding.project_id.value` | The Project ID you copied from AI Foundry in Task 2 |
   | `chat_history.endpoint.value` | `https://devde<inject key="DeploymentID" enableCopy="false" />cosmoskb.documents.azure.com:443/` |
   | `blob_storage.account_url.value` | Find your Storage Account in the resource group (name starts with **devde<inject key="DeploymentID" enableCopy="false" />sa**) and copy its **Blob service endpoint** from the **Endpoints** page |

   >**Understanding the config structure:** Values with `type: "secret"` (like **open-ai-key**, **ai-foundry-key**, **cosmosdb-connection-string**) are resolved from Key Vault at runtime — you do NOT paste actual keys here. Only the `value:` fields for endpoints need to be updated.

1. Save the file (**Ctrl+S**).

1. For local development, you also need to sign in to Azure CLI so the application can authenticate to Key Vault and other services:

   ```
   az login
   ```

   Follow the browser-based authentication flow. When prompted, use:

   - **Email:** <inject key="AzureAdUserEmail"></inject>
   - **Password:** <inject key="AzureAdUserPassword"></inject>

1. Set your active subscription:

   ```
   az account set --subscription "<inject key="Subscription ID" enableCopy="true" />"
   ```

## Summary

In this lab, you:

1. Explored the pre-deployed Azure resources including Key Vault, Cosmos DB, Azure OpenAI, and AI Services.
2. Navigated to Azure AI Foundry and found the Content Understanding project and project ID.
3. Verified the gpt-4o model deployment in Azure OpenAI.
4. Set up the Python virtual environment and installed dependencies.
5. Configured the application with your Azure resource endpoints.

In the next lab, you will start the Function App locally and use Azure Content Understanding to extract structured data from documents.
