# Lab 02: Extract Documents Using Azure Content Understanding

### Estimated Duration: 60 Minutes

## Overview

In this lab, you will use Azure Content Understanding to extract structured data from documents. You will start the Function App locally, upload an extraction configuration that defines what fields to extract, ingest a sample lease agreement PDF, and examine the extracted results in Azure Cosmos DB.

## Objectives

After completing this lab, you will have:

- Understood the extraction configuration schema and field definitions
- Started the Function App locally
- Uploaded an extraction configuration that creates Content Understanding analyzers
- Ingested a document and extracted structured fields using Content Understanding
- Examined extracted data in Azure Cosmos DB with confidence scores

### Task 1: Review the extraction configuration

In this task, you will review the extraction configuration JSON file that defines what fields Azure Content Understanding should extract from documents.

1. In VS Code, navigate to **configs** folder in the Explorer panel and open **document-extraction-v1.0.json**.

1. Review the configuration structure:

   ```json
   {
     "id": "document-extraction-v1.0",
     "name": "document-extraction",
     "version": "v1.0",
     "prompt": "You are a helpful assistant tasked with using the necessary tools...",
     "collection_rows": [{
       "data_type": "LeaseAgreement",
       "field_schema": [
         {"name": "license_grant_scope", "type": "string", "description": "...", "method": "extract"},
         {"name": "lease_duration", "type": "string", "description": "...", "method": "extract"},
         {"name": "termination_conditions", "type": "string", "description": "...", "method": "extract"},
         {"name": "compliance_audit_terms", "type": "string", "description": "...", "method": "extract"},
         {"name": "prohibited_uses", "type": "string", "description": "...", "method": "extract"}
       ],
       "analyzer_id": "test-analyzer"
     }]
   }
   ```

   >**Understanding the config:**
   > - **`collection_rows`** — Defines the document types to process. Each row has a `data_type` (e.g., "LeaseAgreement") and a `field_schema`.
   > - **`field_schema`** — Lists the fields to extract. Each field has a `name`, `type`, `description` (used by Content Understanding as extraction guidance), and `method` (always `"extract"` for field extraction).
   > - **`analyzer_id`** — The ID for the Content Understanding analyzer that will be created. When you upload this config, the application automatically creates a CU analyzer with this schema.
   > - **`prompt`** — The system prompt used by the LLM when answering queries about the extracted data.

1. Also review the **document_samples** folder. It contains a single PDF: **Agreement_for_leasing_or_renting_certain_Microsoft_Software_Products.pdf** — this is the document you will extract data from.

### Task 2: Start the Function App locally

In this task, you will start the Azure Functions application locally so you can interact with the extraction API.

1. In VS Code, open a terminal (**Ctrl+`**) and make sure the virtual environment is activated:

   ```
   cd C:\LabFiles\data-extraction-using-azure-content-understanding
   .venv\Scripts\activate
   ```

1. Start the Function App:

   ```
   func start
   ```

1. Wait for the Function App to start. You should see output listing the available HTTP endpoints:

   ```
   Functions:
     configs_upload_ingest_config: [PUT] http://localhost:7071/api/configs/{name}/versions/{version}
     configs_get_ingest_config: [GET] http://localhost:7071/api/configs/{name}/versions/{version}
     configs_get_default_config: [GET] http://localhost:7071/api/configs/default
     ingest_documents: [POST] http://localhost:7071/api/ingest-documents/{collection_id}/{lease_id}/{document_name}
     query: [POST] http://localhost:7071/api/v1/query
     health_check: [GET] http://localhost:7071/api/v1/health
   ```

   >**Note:** Keep this terminal running. You will use a separate terminal for the remaining tasks.

1. Open a **second terminal** in VS Code (click the **+** icon in the terminal panel) and activate the virtual environment:

   ```
   cd C:\LabFiles\data-extraction-using-azure-content-understanding
   .venv\Scripts\activate
   ```

1. Test the health check endpoint:

   ```
   curl.exe http://localhost:7071/api/v1/health
   ```

   You should see a JSON response showing the status of all connected services (Key Vault, Cosmos DB, OpenAI, Content Understanding, Blob Storage).

### Task 3: Upload the extraction configuration

In this task, you will upload the extraction configuration. This triggers the application to create a **Content Understanding analyzer** with the defined field schema.

1. In the second terminal, upload the extraction configuration:

   ```
   curl.exe -X PUT "http://localhost:7071/api/configs/document-extraction/versions/v1.0" `
     -H "Content-Type: application/json" `
     -d @configs/document-extraction-v1.0.json
   ```

1. Wait for the response (this may take 1–2 minutes). The application is:

   1. Parsing the field schema from the JSON config
   2. Building a Content Understanding analyzer template with `baseAnalyzerId: prebuilt-documentAnalyzer`
   3. Calling the Content Understanding REST API to create the analyzer
   4. Polling the API until the analyzer creation completes
   5. Storing the configuration in Cosmos DB (MongoDB API)

   You should see a success response when complete.

   >**What just happened behind the scenes?** The application called `PUT /contentunderstanding/analyzers/test-analyzer` on the Azure AI Content Understanding API. This created a custom analyzer based on the pre-built document analyzer, configured with your 5 field definitions. The analyzer is now ready to extract those specific fields from any document you send it.

1. Verify the configuration was stored in Cosmos DB. Open the **Azure Portal**, navigate to your **Cosmos DB (MongoDB API)** account (`devde<inject key="DeploymentID" enableCopy="false" />cosmos`).

1. In the left menu, click **Data Explorer**. Expand **data-extraction-db** > **Configurations** and click **Documents**. You should see the uploaded configuration document with the field schema and a computed `extraction_config_hash` (SHA-256 hash of the field definitions).

### Task 4: Ingest a document using Content Understanding

In this task, you will send a PDF document through the extraction pipeline. Azure Content Understanding will analyze the document and extract the fields you defined.

1. In the second terminal, ingest the sample lease agreement:

   ```
   curl.exe -X POST "http://localhost:7071/api/ingest-documents/Collection1/Lease1/MicrosoftLeaseAgreement" `
     -H "Content-Type: application/octet-stream" `
     --data-binary @document_samples/Agreement_for_leasing_or_renting_certain_Microsoft_Software_Products.pdf
   ```

   >**Understanding the URL parameters:**
   > - `Collection1` — The collection ID (groups related documents together)
   > - `Lease1` — The lease ID (identifies a specific lease within the collection)
   > - `MicrosoftLeaseAgreement` — The document name

1. Wait for the response (this may take 2–3 minutes). The extraction pipeline is:

   1. Loading the extraction configuration from Cosmos DB
   2. Sending the PDF bytes to Content Understanding's `POST /contentunderstanding/analyzers/test-analyzer:analyze` endpoint
   3. Polling the operation until the analysis completes
   4. Receiving structured extraction results with field values, confidence scores, and bounding box coordinates
   5. Storing the results in Cosmos DB and the markdown in Blob Storage

1. Check the Function App terminal (first terminal). You should see log messages showing the extraction progress, including the Content Understanding API calls.

### Task 5: Examine extracted data in Cosmos DB

In this task, you will examine the extraction results stored in Cosmos DB to see the structured data that Content Understanding extracted.

1. In the Azure Portal, navigate to your **Cosmos DB (MongoDB API)** account (`devde<inject key="DeploymentID" enableCopy="false" />cosmos`).

1. Open **Data Explorer**. Expand **data-extraction-db** > **Documents** and browse the stored documents.

1. Click on the document for **Collection1**. Examine the structure:

   - **`id`** — Composite key: `Collection1-{extraction_config_hash}`
   - **`config-id`** — References the extraction configuration used
   - **`information.entities`** — Array of extracted lease entities

1. Expand the **`entities`** array and then the **`fields`** object. You should see the 5 extracted fields:

   | Field | What Content Understanding Extracted |
   |-------|--------------------------------------|
   | `license_grant_scope` | The scope of the license grant from the lease agreement |
   | `lease_duration` | Duration terms of the lease |
   | `termination_conditions` | Conditions under which the lease can be terminated |
   | `compliance_audit_terms` | Audit and compliance requirements |
   | `prohibited_uses` | Uses that are explicitly prohibited |

1. For each extracted field, notice the detailed metadata:

   - **`valueString`** — The actual extracted text
   - **`confidence`** — A score between 0 and 1 indicating extraction confidence
   - **`spans`** — Character offset and length in the original document
   - **`source`** — Bounding box coordinates (page, x, y positions) for traceability

   >**Why are confidence scores and bounding boxes important?** Confidence scores help you assess extraction reliability — low-confidence extractions may need human review. Bounding boxes enable you to highlight or link back to the exact location in the source document where the data was found, providing full traceability.

1. Go back to your resource group and navigate to the **Storage Account** (name starts with `devde<inject key="DeploymentID" enableCopy="false" />sa`). Click **Data storage** > **Containers** > **processed**. You should see the markdown file generated by Content Understanding — this is the full document converted to structured markdown format.

## Summary

In this lab, you:

1. Reviewed the extraction configuration schema that defines what fields to extract from documents.
2. Started the Function App locally and verified the health check.
3. Uploaded the extraction configuration, which automatically created a Content Understanding analyzer.
4. Ingested a lease agreement PDF and extracted 5 structured fields using Azure Content Understanding.
5. Examined the extraction results in Cosmos DB, including confidence scores and bounding box coordinates.

In the next lab, you will query the extracted data using natural language powered by Azure OpenAI and Semantic Kernel.
