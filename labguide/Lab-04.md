# Lab 04: Deploy to Azure and Monitor

### Estimated Duration: 45 Minutes

## Overview

In this lab, you will deploy the document extraction Function App to Azure and test the deployed endpoints. You will configure the deployed application with the correct settings, run end-to-end tests against the cloud-hosted API, and monitor application performance using Application Insights.

## Objectives

After completing this lab, you will have:

- Deployed the Function App to Azure
- Configured the deployed application settings
- Tested all deployed endpoints (health, config, ingest, query)
- Monitored the application with Application Insights live metrics

### Task 1: Deploy the Function App to Azure

In this task, you will deploy the Function App to Azure using Azure Functions Core Tools.

1. In VS Code, open a terminal and ensure you are in the project root with the virtual environment activated:

   ```
   cd C:\LabFiles\data-extraction-using-azure-content-understanding
   .venv\Scripts\activate
   ```

1. Stop the locally running Function App by pressing **Ctrl+C** in the terminal running `func start`.

1. Retrieve your **Function App name** from Azure. The ARM deployment created a Function App with a random suffix, so the exact name varies per deployment:

   ```
   $funcApp = (az functionapp list --resource-group <inject key="Resource Group Name" enableCopy="false" /> --query "[0].name" -o tsv)
   echo "Your Function App name is: $funcApp"
   ```

   >**Note:** The output should show a name like `devde<inject key="DeploymentID" enableCopy="false" />func*****` where `*****` is a random 5-character suffix. You will use `$funcApp` in subsequent commands.

1. Copy the **requirements.txt** file into the `src/` directory so the Azure Functions deployment can find it:

   ```
   Copy-Item requirements.txt src\
   ```

1. Deploy the Function App to Azure:

   ```
   func azure functionapp publish $funcApp --python --script-root ./src/
   ```

1. Wait for the deployment to complete (this may take a few minutes). You should see output ending with:

   ```
   Remote build succeeded!
   ```

### Task 2: Configure the deployed application

In this task, you will update the application configuration for the deployed environment.

1. Open **src/resources/app_config.yaml** in VS Code and scroll down to the `dev:` section (below the `local:` section). The deployed Function App reads the `dev:` section because the `ENVIRONMENT` variable defaults to `"dev"`.

1. Update the `dev:` section with the same Azure resource endpoints you configured for the `local:` section in Lab 01:

   | Setting | Value |
   |---------|-------|
   | `key_vault_uri` | `https://devde<inject key="DeploymentID" enableCopy="false" />kv.vault.azure.net/` |
   | `tenant_id` | Your Azure tenant ID (same as `local:`) |
   | `user_managed_identity.client_id` | Copy the `APP_CLIENT_ID` value from your Function App's **Configuration > Application settings** in the Azure Portal |
   | `llm.endpoint` | `https://aoaidevde<inject key="DeploymentID" enableCopy="false" />.openai.azure.com/openai/deployments/gpt-4o` (same as `local:`) |
   | `content_understanding.endpoint` | `https://devde<inject key="DeploymentID" enableCopy="false" />ais.cognitiveservices.azure.com/` (same as `local:`) |
   | `content_understanding.project_id` | Your AI Foundry project ID (same as `local:`) |
   | `chat_history.endpoint` | `https://devde<inject key="DeploymentID" enableCopy="false" />cosmoskb.documents.azure.com:443/` |
   | `blob_storage.account_url` | Find your Storage Account in the resource group (name starts with `devde<inject key="DeploymentID" enableCopy="false" />sa`) and use its Blob service endpoint |

   >**Tip:** The easiest approach is to copy all values from your `local:` section and paste them into the corresponding `dev:` fields. The **secret references** (like `cosmosdb-connection-string`, `open-ai-key`, `ai-foundry-key`) do **not** need to change — they point to the same Key Vault secrets.

1. Save the file and **redeploy** the Function App so the updated config is included:

   ```
   Copy-Item requirements.txt src\
   func azure functionapp publish $funcApp --python --script-root ./src/
   ```

   Wait for the deployment to complete before testing.

### Task 3: Test the deployed endpoints

In this task, you will test all the deployed API endpoints to verify the full extraction pipeline works in Azure.

1. Test the **health check** on the deployed endpoint:

   ```
   curl.exe https://$funcApp.azurewebsites.net/api/v1/health
   ```

1. Verify all services show as **healthy**. The deployed Function App uses its **system-assigned managed identity** for authentication to Azure services instead of user credentials.

1. Upload the extraction configuration to the **deployed** endpoint:

   ```
   curl.exe -X PUT "https://$funcApp.azurewebsites.net/api/configs/document-extraction/versions/v1.0" `
     -H "Content-Type: application/json" `
     -d @configs/document-extraction-v1.0.json
   ```

1. Ingest the document to the **deployed** endpoint:

   ```
   curl.exe -X POST "https://$funcApp.azurewebsites.net/api/ingest-documents/Collection1/Lease1/MicrosoftLeaseAgreement" `
     -H "Content-Type: application/octet-stream" `
     --data-binary @document_samples/Agreement_for_leasing_or_renting_certain_Microsoft_Software_Products.pdf
   ```

1. Query the deployed endpoint:

   ```
   curl.exe -X POST "https://$funcApp.azurewebsites.net/api/v1/query" `
     -H "Content-Type: application/json" `
     -H "x-user: labuser@contoso.com" `
     -d "{\"cid\": \"Collection1\", \"sid\": \"azure-session1\", \"query\": \"Summarize all key terms in Collection1.\"}"
   ```

1. Verify that the response includes the answer with citations, confirming the full pipeline works end-to-end in Azure.

### Task 4: Monitor with Application Insights

In this task, you will use Application Insights to monitor the deployed Function App's performance.

1. In the Azure Portal, navigate to your **Function App** (the name you captured in the `$funcApp` variable). In the left menu, click **Settings** > **Application Insights**, then click the **Application Insights resource name** link to open the connected App Insights instance.

   >**Note:** The Function App has its own Application Insights resource (auto-created during deployment). Make sure you open the one linked to the Function App.

1. Once in the Application Insights resource, click on **Investigate** > **Live Metrics** in the left menu to see real-time request rates, response times, and failures.

1. While Live Metrics is open, send another query to the deployed endpoint from your terminal:

   ```
   curl.exe -X POST "https://$funcApp.azurewebsites.net/api/v1/query" `
     -H "Content-Type: application/json" `
     -H "x-user: labuser@contoso.com" `
     -d "{\"cid\": \"Collection1\", \"sid\": \"azure-session1\", \"query\": \"What are the prohibited uses?\"}"
   ```

1. Observe the Live Metrics dashboard update in real-time — you should see the incoming request, the response time, and the dependency calls to Cosmos DB and Azure OpenAI.

1. Navigate to **Investigate** > **Transaction search** in the left menu. Click **See all data in the last 24 hours** to view the recent requests.

1. Click on one of the query requests to open the **end-to-end transaction details**. This view shows the complete request lifecycle:

   - The initial HTTP request to the Function App
   - Dependency calls to Cosmos DB (retrieve config, get extracted data, store chat history)
   - Dependency calls to Azure OpenAI (LLM inference)
   - Response time breakdown for each component

   >**Why is this useful?** Application Insights lets you identify bottlenecks in the extraction pipeline. If Content Understanding extraction is slow, you'll see it in the dependency timing. If the LLM response takes too long, you can identify that separately. This is critical for production monitoring.

## Summary

In this lab, you:

1. Deployed the Function App to Azure using Azure Functions Core Tools.
2. Configured the deployed application with the correct Azure resource endpoints.
3. Tested all deployed endpoints — health check, config upload, document ingestion, and natural language query.
4. Monitored the application with Application Insights live metrics and transaction search, understanding the end-to-end request lifecycle.

## Congratulations!

You have completed all labs in the **Data Extraction Using Azure Content Understanding** workshop. You have successfully:

- Explored Azure AI Content Understanding and Azure AI Foundry
- Configured a document extraction pipeline with custom field schemas
- Extracted structured data from a lease agreement using Content Understanding analyzers
- Queried the extracted data using natural language powered by Azure OpenAI and Semantic Kernel
- Deployed the solution to Azure and monitored it with Application Insights

These skills enable you to build intelligent document processing solutions that automatically extract, store, and query structured information from unstructured documents at scale.
