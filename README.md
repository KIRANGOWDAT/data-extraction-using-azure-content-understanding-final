# Data Extraction Using Azure Content Understanding

Hands-on lab for building intelligent document extraction pipelines using Azure Content Understanding, Azure OpenAI, Cosmos DB, and Azure Functions.

## Lab Exercises

| # | Exercise | Duration |
|---|----------|----------|
| 1 | [Environment Setup and Architecture Overview](labguide/Lab-01.md) | 30 min |
| 2 | [Deploying Azure Infrastructure with Terraform](labguide/Lab-02.md) | 75 min |
| 3 | [Configuring the Application](labguide/Lab-03.md) | 60 min |
| 4 | [Document Extraction Configuration and Ingestion](labguide/Lab-04.md) | 75 min |
| 5 | [Querying Documents and Deploying to Azure](labguide/Lab-05.md) | 75 min |

**Total Duration:** ~5.25 hours

## Architecture

This lab covers three core workflows:
- **Document Enquiry** — Query documents with natural language using Azure OpenAI
- **Configuration Upload** — Create extraction configurations and CU analyzers
- **Document Ingestion** — Ingest documents, extract fields with bounding boxes and confidence scores

## Azure Services Used

- Azure Content Understanding
- Azure OpenAI Service (gpt-4o)
- Azure Functions (Python)
- Azure Cosmos DB (Mongo API + SQL API)
- Azure Key Vault
- Azure Storage Account
- Azure Application Insights
- Azure AI Foundry
- Azure Log Analytics Workspace

## Prerequisites

All prerequisites are pre-installed on the Lab VM:
- Python 3.12+, Azure CLI 2.60+, Terraform 1.5+
- Azure Functions Core Tools v4, Git, Node.js 18+
- Visual Studio Code with extensions (Python, Azure Functions, REST Client, Terraform)

## CloudLabs Deployment

The `cloudlabs-setup/` folder contains everything needed for CloudLabs portal deployment:

| File | Purpose |
|------|---------|
| `deploy.json` | ARM template — provisions Lab VM with all tools pre-installed |
| `deploy.parameters.json` | Parameters file with CloudLabs placeholder tokens |
| `psscript.ps1` | VM setup script — installs Python, Az CLI, Terraform, VS Code, etc. |
| `masterdoc.json` | Lab guide manifest for CloudLabs portal rendering |

## Repository Structure

```
├── labguide/
│   ├── Lab-01.md ... Lab-05.md    # Lab guide markdown files
│   └── masterdoc.json             # Lab metadata
├── media/
│   ├── Lab-01/ ... Lab-05/        # Screenshots for each exercise
├── cloudlabs-setup/
│   ├── deploy.json                # ARM template
│   ├── deploy.parameters.json     # Parameters
│   ├── psscript.ps1               # VM setup script
│   └── masterdoc.json             # CloudLabs masterdoc
└── README.md
```
