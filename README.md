# Data Extraction Using Azure Content Understanding

Hands-on lab for building intelligent document extraction pipelines using Azure Content Understanding, Azure OpenAI, Cosmos DB, and Azure Functions.

## Lab Exercises

| # | Exercise | Duration |
|---|----------|----------|
| 0 | [Getting Started](labguide/gettingstarted.md) | 10 min |
| 1 | [Create Azure AI Services and Explore Content Understanding](labguide/Lab-01.md) | 60 min |
| 2 | [Configure and Extract Documents Using Content Understanding](labguide/Lab-02.md) | 60 min |
| 3 | [Query Extracted Data with Azure OpenAI](labguide/Lab-03.md) | 45 min |
| 4 | [Deploy to Azure and Monitor](labguide/Lab-04.md) | 45 min |

**Total Duration:** ~3.5 hours

## Architecture

This lab covers three core workflows:
- **Configuration Upload** - Create extraction configurations and Content Understanding analyzers
- **Document Ingestion** - Ingest documents, extract fields with bounding boxes and confidence scores
- **Document Query** - Query extracted data with natural language using Azure OpenAI and Semantic Kernel

## Azure Services Used

- Azure Content Understanding (AI Services)
- Azure OpenAI Service (gpt-4o)
- Azure Functions (Python)
- Azure Cosmos DB (MongoDB API + SQL API)
- Azure Key Vault
- Azure Storage Account
- Azure Application Insights
- Azure AI Foundry
- Azure Log Analytics Workspace

## CloudLabs Deployment

The `cloudlabs-setup/` folder contains everything needed for CloudLabs portal deployment:

| File | Purpose |
|------|---------|
| `deploy.json` | ARM template - provisions all Azure resources and Lab VM |
| `deploy.parameters.json` | Parameters file with CloudLabs placeholder tokens |
| `psscript.ps1` | VM setup script - installs Python, Azure CLI, VS Code, etc. |
| `masterdoc.json` | Lab guide manifest for CloudLabs portal rendering |

## Repository Structure

```
├── cloudlabs-setup/          # ARM template, scripts, masterdoc
├── configs/                   # Extraction configuration JSON
├── document_samples/          # Sample documents for ingestion
├── labguide/                  # Lab guide markdown files
├── media/                     # Screenshots for each lab
├── src/                       # Azure Functions Python app
├── requirements.txt           # Python dependencies
└── README.md
```
