# Data Extraction Using Azure Content Understanding

### Estimated Duration: 3 Hours

## Overview

In this lab, you will build an intelligent document extraction and query pipeline using **Azure AI Content Understanding** — a service within Azure AI Foundry that extracts structured data from unstructured documents such as lease agreements, contracts, and invoices.

You will configure custom extraction field schemas, ingest PDF documents through Content Understanding analyzers, store the extracted fields in Azure Cosmos DB, and query the results using natural language powered by **Azure OpenAI (gpt-4o)** and **Semantic Kernel**. Finally, you will deploy the solution as an Azure Function App and monitor it with Application Insights.

## Objectives

By completing this lab, you will learn to:

- **Explore Azure AI Content Understanding** — Understand how Content Understanding extracts structured data from documents using custom analyzers and field schemas within Azure AI Foundry.

- **Configure a Document Extraction Pipeline** — Set up a Python-based Azure Functions application that connects to Content Understanding, Azure OpenAI, Cosmos DB, Key Vault, and Blob Storage.

- **Extract Structured Data from Documents** — Define extraction field schemas (e.g., lease duration, compliance terms, prohibited uses), ingest PDF documents, and examine the extracted results with confidence scores and bounding box coordinates.

- **Query Extracted Data Using Natural Language** — Use Azure OpenAI's gpt-4o model with Semantic Kernel to ask questions about extracted document data and explore multi-turn conversations with chat history.

- **Deploy and Monitor on Azure** — Deploy the extraction pipeline as an Azure Function App and monitor performance using Application Insights live metrics.

## Pre-requisites

The following tools and services are **pre-installed** on your lab VM — no manual setup is needed:

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.12 | Application runtime |
| Azure CLI | Latest | Azure resource management |
| Azure Functions Core Tools | v4 | Local function app development |
| Git | Latest | Source control |
| Node.js | 18 LTS | Azure Functions dependency |
| Visual Studio Code | Latest | Code editor with extensions |
| .NET 8.0 SDK | Latest | Azure Functions host |

The following **Azure resources** are pre-deployed automatically:

| Resource | Purpose |
|----------|---------|
| Azure AI Services (Content Understanding) | Document extraction engine |
| Azure OpenAI (gpt-4o) | Natural language query responses |
| Azure Cosmos DB (MongoDB API) | Stores extraction configs and extracted document data |
| Azure Cosmos DB (SQL API) | Stores chat history per user session |
| Azure Key Vault | Securely stores API keys and connection strings |
| Azure Storage Account | Stores processed document files |
| Azure Function App | Hosts the extraction and query API |
| Application Insights + Log Analytics | Monitoring and observability |

## Architecture

The solution implements two main workflows — **Document Ingestion** (extraction) and **Document Enquiry** (querying) — running as HTTP-triggered Azure Functions.

![Architecture Diagram](https://raw.githubusercontent.com/KIRANGOWDAT/data-extraction-using-azure-content-understanding-final/master/media/architecture.png)

### Document Ingestion Workflow (Right Side)

When a user uploads a document:

1. The Function App retrieves the **extraction configuration** from Cosmos DB (MongoDB API), which defines what fields to extract (e.g., lease duration, compliance terms).
2. The document is sent to **Azure AI Content Understanding**, which uses the configured analyzer schema to extract structured fields — returning values with confidence scores and bounding box coordinates.
3. The extracted markdown is stored in **Azure Blob Storage**.
4. The structured extraction results are stored in **Azure Cosmos DB** (MongoDB API) for querying.

### Document Enquiry Workflow (Left Side)

When a user submits a natural language query:

1. The Function App loads the extraction configuration from Cosmos DB.
2. **Semantic Kernel** uses Azure OpenAI (gpt-4o) with forced tool calling to extract the collection ID from the user's query.
3. The extracted document data is retrieved from Cosmos DB by collection ID.
4. Azure OpenAI formulates a response using the extracted data as context, returning an answer with citations.
5. The conversation is stored in **Cosmos DB (SQL API)** for multi-turn chat history.

### Shared Infrastructure

- **Azure Key Vault** stores all secrets (Cosmos DB connection string, OpenAI API key, AI Services key). The app resolves secrets at runtime via Key Vault references.
- **Azure Monitor** (Application Insights + Log Analytics) provides request tracing, latency metrics, and failure tracking.

## Accessing Your Lab Environment

Once you're ready to dive in, your virtual machine and **Lab Guide** will be right at your fingertips within your web browser.

### Virtual Machine & Lab Guide

Your virtual machine is your workhorse throughout the lab. The lab guide is your roadmap to success.

   ![](../media/gettingstarted/image01.png)

## Exploring Your Lab Resources

To get a better understanding of your lab resources and credentials, navigate to the **Environment** tab.

   ![](../media/gettingstarted/image02.png)

## Utilizing the Split Window Feature

For convenience, you can open the lab guide in a separate window by selecting the **Split Window** button from the top right corner.

   ![](../media/gettingstarted/image03.png)

## Managing Your Virtual Machine

Feel free to **Start, Restart, or Stop** your virtual machine as needed from the **Resources** tab. Your experience is in your hands!

   ![](../media/gettingstarted/image04.png)

## Let's Get Started with Azure Portal

1. On your virtual machine, click on the **Azure Portal** shortcut on the desktop.

1. You'll see the **Sign into Microsoft Azure** tab. Enter your credentials:

   - **Email/Username:** <inject key="AzureAdUserEmail"></inject>

1. Next, provide your password and click **Sign in**:

   - **Password:** <inject key="AzureAdUserPassword"></inject>

1. If you see the pop-up **Stay Signed in?**, click **Yes**.

1. If a **Welcome to Microsoft Azure** pop-up window appears, click **Cancel** to skip the tour.

## Support Contact

The CloudLabs support team is available 24/7, 365 days a year, via email and live chat to ensure seamless assistance at any time.

**Learner Support Contacts:**

- Email Support: cloudlabs-support@spektrasystems.com
- Live Chat Support: https://cloudlabs.ai/labs-support

Click **Next** from the bottom right corner to start Lab 01!
