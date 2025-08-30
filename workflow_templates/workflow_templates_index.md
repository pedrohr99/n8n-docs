# Index of n8n workflow templates

This document indexes the n8n workflow JSON templates present in this repository. It provides operational metadata and a "Metadata for RAG" block to facilitate ingestion into a Retrieval-Augmented Generation (RAG) system and ChatLLM training.

## Table of Contents

- [Email_Summary_Agent.json — Email Summary Agent](#email_summary_agentjson--email-summary-agent)
- [Gmail_AI_Email_Manager.json — Email Manager](#gmail_ai_email_managerjson--email-manager)
- [Intelligent_Email_Organization_AI_Content_Classification_Gmail.json — Auto Gmail Labeling (Powered by OpenAI)](#intelligent_email_organization_ai_content_classification_gmailjson--auto-gmail-labeling-powered-by-openai)
- [Automate_Email_Calendar_Management_Gmail_Google_Calendar_GPT-4o.json — [AOE]  Inbox & Calendar Management Agent](#automate_email_calendar_management_gmail_google_calendar_gpt-4ojson--aoe--inbox--calendar-management-agent)
- [Analyze_Sort_Suspicious_Email_Contents_ChatGPT.json — Analyze and Sort Suspicious Email Contents (ChatGPT)](#analyze_sort_suspicious_email_contents_chatgptjson--analyze-and-sort-suspicious-email-contents-chatgpt)
- [Screen_Score_Resumes_Gmail_Sheets_AI.json — Resume Screener from Gmail to Sheets](#screen_score_resumes_gmail_sheets_aijson--resume-screener-from-gmail-to-sheets)
- [Automate_Email_Filtering_AI_Summarization.json — Automate Email Filtering and AI Summarization (100% Free and Effective)](#automate_email_filtering_ai_summarizationjson--automate-email-filtering-and-ai-summarization-100-free-and-effective)
- [Scrape_and_summarize_webpages_with_AI.json — Scrape and Summarize Webpages with AI](#scrape_and_summarize_webpages_with_aijson--scrape-and-summarize-webpages-with-ai)

## Email_Summary_Agent.json — Email Summary Agent

### Functional summary — Email Summary Agent

- Runs daily at 07:00 (Schedule Trigger) in the Asia/Kolkata timezone.
- Retrieves all emails from the past 24 hours using the Gmail node with a dynamic filter (query `after:YYYY/MM/DD` calculated for yesterday) for the account `isb.quantana@quantana.in`.
- Aggregates and structures key fields (id, From, To, CC, snippet) before inference.
- Produces a structured summary (JSON) using an OpenAI model (gpt-4o-mini) based on the aggregated data.
- Sends an HTML report email containing the summary and action items, using a dynamic subject line with a date range.

### Metadata — Email Summary Agent

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| scheduleTrigger | daily@07:00 | Gmail, OpenAI | gpt-4o-mini | Asia/Kolkata | html_email, json_summary | productivity | Gmail filter for last 24h; aggregated fields: id, From, To, CC, snippet; dynamic subject line |

### Metadata for RAG — Email Summary Agent

```json
{
  "name": "Email Summary Agent",
  "source_url": "https://n8n.io/workflows/2722-email-summary-agent/",
  "repo_path": "workflow_templates/json/Email_Summary_Agent.json",
  "nodes_count": 9,
  "triggers": ["schedule:daily@07:00"],
  "connectors": ["gmail", "openai"],
  "timezone": "Asia/Kolkata",
  "outputs": ["html_email", "json_summary"],
  "domain": "productivity",
  "last_updated_utc": "unknown"
}
```

### Reference — Email Summary Agent

Official workflow page on n8n: [https://n8n.io/workflows/2722-email-summary-agent/](https://n8n.io/workflows/2722-email-summary-agent/)

## Gmail_AI_Email_Manager.json — Email Manager

### Functional summary — Email Manager

- Trigger: Gmail Trigger polling every minute (pollTimes: everyMinute).
- Retrieves full message metadata and body using the Gmail node (operation: get) referencing the incoming message id.
- Uses an AI Agent node (Anthropic) with model `claude-sonnet-4-20250514` to classify emails and determine a Label ID as output.
- Parses structured output with a Structured Output Parser node to extract the `label ID` and then applies that label via a Gmail node (operation: addLabels).
- Performs secondary queries to check prior sent messages (`Check Sent` node with `q = =to:{{ $fromAI('email') }}` and labelIds `SENT`) and to retrieve related messages (`Get Email` node with `q = =from:{{ $fromAI('email') }}`).

### Metadata — Email Manager

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| gmailTrigger | everyMinute | Gmail, Anthropic | claude-sonnet-4-20250514 | N/D | structured_label_id, gmail_addLabels | productivity | Uses AI agent with system message; Get Email & Check Sent use `$fromAI('email')`; credentials redacted |

### Metadata for RAG — Email Manager

```json
{
  "name": "Email Manager",
  "source_url": "https://n8n.io/workflows/4722-gmail-ai-email-manager/",
  "repo_path": "workflow_templates/json/Gmail_AI_Email_Manager.json",
  "nodes_count": 8,
  "triggers": ["gmailTrigger:everyMinute"],
  "connectors": ["gmail", "anthropic"],
  "timezone": "N/D",
  "outputs": ["structured_label_id", "gmail_addLabels"],
  "domain": "productivity",
  "last_updated_utc": "unknown"
}
```

### Reference — Email Manager

Official workflow page on n8n: [https://n8n.io/workflows/4722-gmail-ai-email-manager/](https://n8n.io/workflows/4722-gmail-ai-email-manager/)

## Intelligent_Email_Organization_AI_Content_Classification_Gmail.json — Auto Gmail Labeling (Powered by OpenAI)

### Functional summary — Auto Gmail Labeling (Powered by OpenAI)

- Trigger: Schedule Trigger running every 2 minutes.
- Fetches messages with `Gmail - Get All Messages` using `limit: 20` and `readStatus: both` and then iterates per message with `Loop Over Items`.
- Extracts key fields (id, from, headers.subject, text) via `Extract Email Data` and sends content to an AI agent for labeling.
- Uses OpenAI (`gpt-4.1-nano`) via `OpenAI Chat Model` / agent node to determine a single label; stores AI output and maps it to existing Gmail labels or creates a new label, then applies it via Gmail `addLabels`.
- Filters out messages that already contain excluded labels using `Filter Emails Without Excluded Labels` (list of excluded label IDs present in code node).

### Metadata — Auto Gmail Labeling (Powered by OpenAI)

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| scheduleTrigger | every2m | Gmail, OpenAI | gpt-4.1-nano | N/D | gmail_addLabels, created_label, structured_json_output | productivity | Limit=20; splitInBatches; excludes messages with certain labels; credentials redacted |

### Metadata for RAG — Auto Gmail Labeling (Powered by OpenAI)

```json
{
  "name": "Auto Gmail Labeling (Powered by OpenAI)",
  "source_url": "https://n8n.io/workflows/4557-intelligent-email-organization-with-ai-powered-content-classification-for-gmail/",
  "repo_path": "workflow_templates/json/Intelligent_Email_Organization_AI_Content_Classification_Gmail.json",
  "nodes_count": 18,
  "triggers": ["schedule:every2minutes"],
  "connectors": ["gmail", "openai"],
  "timezone": "N/D",
  "outputs": ["gmail_addLabels", "created_label", "structured_json_output"],
  "domain": "productivity",
  "last_updated_utc": "unknown"
}
```

### Reference — Auto Gmail Labeling (Powered by OpenAI)

Official workflow page on n8n: [https://n8n.io/workflows/4557-intelligent-email-organization-with-ai-powered-content-classification-for-gmail/](https://n8n.io/workflows/4557-intelligent-email-organization-with-ai-powered-content-classification-for-gmail/)

## Automate_Email_Calendar_Management_Gmail_Google_Calendar_GPT-4o.json — [AOE]  Inbox & Calendar Management Agent

### Functional summary — [AOE]  Inbox & Calendar Management Agent

- Listens for chat triggers and workflow execution triggers; supports manual testing via a Manual Trigger.
- Retrieves recent emails and Gmail threads, summarizes threads to text, and creates embeddings for vector storage and retrieval.
- Provides tools to create drafts, delete messages, and add calendar events using Gmail and Google Calendar tools; uses OpenAI chat models (gpt-4o / gpt-4o-mini / gpt-4.1-mini) for assistant logic and summarization.
- Maintains a conversation window buffer memory and an in-memory vector store for thread history to enable contextual responses and research on past conversations.
- Classifies emails, applies labels, and can add calendar entries based on assistant outputs.

### Metadata — [AOE]  Inbox & Calendar Management Agent

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| chatTrigger, executeWorkflowTrigger, manualTrigger, gmailTrigger | N/A | Gmail, Google Calendar, OpenAI | gpt-4o, gpt-4o-mini, gpt-4.1-mini | N/D | email_drafts, email_delete, calendar_events, embeddings, vectorstore_entries, summarized_thread_text | productivity | Window buffer memory + vector store; multiple Gmail & Calendar tool nodes; credentials redacted |

### Metadata for RAG — [AOE]  Inbox & Calendar Management Agent

```json
{
  "name": "[AOE]  Inbox & Calendar Management Agent",
  "source_url": "https://n8n.io/workflows/4366-automate-email-and-calendar-management-with-gmail-google-calendar-and-gpt-4o-ai/",
  "repo_path": "workflow_templates/json/Automate_Email_Calendar_Management_Gmail_Google_Calendar_GPT-4o.json",
  "nodes_count": 38,
  "triggers": ["chatTrigger", "executeWorkflowTrigger", "manualTrigger", "gmailTrigger"],
  "connectors": ["gmail", "google_calendar", "openai"],
  "timezone": "N/D",
  "outputs": ["email_drafts", "email_delete", "calendar_events", "embeddings", "vectorstore_entries", "summarized_thread_text"],
  "domain": "productivity",
  "last_updated_utc": "unknown"
}
```

### Reference — [AOE]  Inbox & Calendar Management Agent

Official workflow page on n8n: [https://n8n.io/workflows/4366-automate-email-and-calendar-management-with-gmail-google-calendar-and-gpt-4o-ai/](https://n8n.io/workflows/4366-automate-email-and-calendar-management-with-gmail-google-calendar-and-gpt-4o-ai/)

## Analyze_Sort_Suspicious_Email_Contents_ChatGPT.json — Analyze and Sort Suspicious Email Contents (ChatGPT)

### Functional summary — Analyze and Sort Suspicious Email Contents (ChatGPT)

- Monitors Gmail (every minute) and (optionally) Microsoft Outlook for incoming messages; extracts headers, body and key fields.
- Converts email HTML body to a screenshot via hcti.io and retrieves the image for attachment and visual inspection.
- Analyzes email HTML and headers with an OpenAI model (gpt-4o) producing structured JSON indicating `malicious` and a verbose `summary`.
- Based on the analysis, automatically creates Jira tickets for potentially malicious or potentially benign emails and attaches the screenshot and email body text.
- Converts email body to a text file and supports uploading both screenshots and text to Jira for incident handling.

### Metadata — Analyze and Sort Suspicious Email Contents (ChatGPT)

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| gmailTrigger, microsoftOutlookTrigger (disabled) | everyMinute | Gmail, Microsoft Outlook (Graph), hcti.io (HTTP), OpenAI, Jira | gpt-4o | N/D | jira_ticket_malicious, jira_ticket_benign, email_screenshot, email_body_text, json_analysis | security | Microsoft Graph headers; hcti.io HTML screenshot; OpenAI JSON output enabled |

### Metadata for RAG — Analyze and Sort Suspicious Email Contents (ChatGPT)

```json
{
  "name": "Analyze and Sort Suspicious Email Contents (ChatGPT)",
  "source_url": "https://n8n.io/workflows/2666-analyze-and-sort-suspicious-email-contents-with-chatgpt/",
  "repo_path": "workflow_templates/json/Analyze_Sort_Suspicious_Email_Contents_ChatGPT.json",
  "nodes_count": 25,
  "triggers": ["gmailTrigger:everyMinute", "microsoftOutlookTrigger:everyMinute(disabled)"],
  "connectors": ["gmail", "microsoft_outlook", "openai", "jira", "http(hcti.io)"],
  "timezone": "N/D",
  "outputs": ["jira_ticket_malicious", "jira_ticket_benign", "email_screenshot", "email_body_text", "json_analysis"],
  "domain": "security",
  "last_updated_utc": "unknown"
}
```

### Reference — Analyze and Sort Suspicious Email Contents (ChatGPT)

Official workflow page on n8n: [https://n8n.io/workflows/2666-analyze-and-sort-suspicious-email-contents-with-chatgpt/](https://n8n.io/workflows/2666-analyze-and-sort-suspicious-email-contents-with-chatgpt/)

## Screen_Score_Resumes_Gmail_Sheets_AI.json — Resume Screener from Gmail to Sheets

### Functional summary — Resume Screener from Gmail to Sheets

- Triggers when a new email with attachments is received in Gmail (unread, label `UNREAD`), polling hourly (minute 1).
- Downloads PDF attachments and extracts text from the PDF using `Extract text from PDF File`.
- Sends extracted text to an AI Agent to evaluate the resume, extracting name, email, LinkedIn, and a score; output is parsed by a Structured Output Parser.
- Appends the parsed results and original resume text to a Google Sheets document (`Add Resume Evaluation to Google Sheets`).
- Includes a sticky-note with prerequisites such as n8n installation, OpenAI API key, and enabling Google Sheets/Drive APIs.

### Metadata — Resume Screener from Gmail to Sheets

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| gmailTrigger | hourly@mm=1 | Gmail, Google Sheets, OpenAI | gpt-4o-mini | N/D | google_sheet_row, extracted_text, structured_output | hr | Filters: has:attachment & UNREAD; PDF extraction + structured output parsing; credentials redacted |

### Metadata for RAG — Resume Screener from Gmail to Sheets

```json
{
  "name": "Resume Screener from Gmail to Sheets",
  "source_url": "https://n8n.io/workflows/3546-screen-and-score-resumes-from-gmail-to-sheets-with-ai/",
  "repo_path": "workflow_templates/json/Screen_Score_Resumes_Gmail_Sheets_AI.json",
  "nodes_count": 7,
  "triggers": ["gmailTrigger:everyHour"],
  "connectors": ["gmail", "google_sheets", "openai"],
  "timezone": "N/D",
  "outputs": ["google_sheet_row", "extracted_text", "structured_output"],
  "domain": "hr",
  "last_updated_utc": "unknown"
}
```

### Reference — Resume Screener from Gmail to Sheets

Official workflow page on n8n: [https://n8n.io/workflows/3546-screen-and-score-resumes-from-gmail-to-sheets-with-ai/](https://n8n.io/workflows/3546-screen-and-score-resumes-from-gmail-to-sheets-with-ai/)

## Automate_Email_Filtering_AI_Summarization.json — Automate Email Filtering and AI Summarization (100% Free and Effective)

### Functional summary — Automate Email Filtering and AI Summarization (100% Free and Effective)

- Triggers: Gmail Trigger polling hourly (everyHour) with filter `labelIds: ["CATEGORY_PERSONAL"]` and downloads no attachments.
- Filters incoming emails using a sender-name condition (`YOUR_SENDER_NAME_FILTER`) and extracts plain-text or HTML-converted content with fallback and truncation to a safe length.
- Sends concise summaries to an AI Agent (agent node) that returns a short, focused summary of the email content.
- Appends or updates a Google Sheets row with the generated summary and key metadata (Date, Sender Name, Sender Email, Subject).
- Supports configurable AI model replacement (Groq/llama) and Groq Chat Model integration for local/alternative LLM usage.

### Metadata — Automate Email Filtering and AI Summarization (100% Free and Effective)

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| gmailTrigger | hourly@mm=59 | Gmail, Google Sheets, Groq (lmChatGroq) | llama-3.1-8b-instant | N/D | google_sheet_row, short_summary_text | productivity | Sender filter placeholder; HTML->text fallback; Groq model node present (agent model unspecified) |

### Metadata for RAG — Automate Email Filtering and AI Summarization (100% Free and Effective)

```json
{
  "name": "Automate Email Filtering and AI Summarization (100% Free and Effective)",
  "source_url": "https://n8n.io/workflows/5678-automate-email-filtering-and-ai-summarization-100percent-free-and-effective-works-724/",
  "repo_path": "workflow_templates/json/Automate_Email_Filtering_AI_Summarization.json",
  "nodes_count": 14,
  "triggers": ["gmailTrigger:everyHour"],
  "connectors": ["gmail", "google_sheets", "groq"],
  "timezone": "N/D",
  "outputs": ["google_sheet_row", "short_summary_text"],
  "domain": "productivity",
  "last_updated_utc": "unknown"
}
```

### Reference — Automate Email Filtering and AI Summarization (100% Free and Effective)

Official workflow page on n8n: [https://n8n.io/workflows/5678-automate-email-filtering-and-ai-summarization-100percent-free-and-effective-works-724/](https://n8n.io/workflows/5678-automate-email-filtering-and-ai-summarization-100percent-free-and-effective-works-724/)

## Scrape_and_summarize_webpages_with_AI.json — Scrape and Summarize Webpages with AI

### Functional summary — Scrape and Summarize Webpages with AI

- Trigger manual: executes on demand via Manual Trigger.
- Descarga la página índice de ensayos de Paul Graham (`articles.html`).
- Extrae los enlaces de ensayos (selector `table table a`), los divide en items y limita a los primeros 3.
- Recupera el HTML de cada ensayo y extrae el `<title>` y el texto del `body` (omite `img, nav`).
- Carga el texto como documento, lo fragmenta con Recursive Character Text Splitter (`chunkSize=6000`).
- Ejecuta una cadena de resumen (LangChain Summarization Chain) usando el modelo OpenAI `gpt-4o-mini`.
- Fusiona título y resumen y limpia la salida dejando: `title`, `summary`, `url`.

### Metadata — Scrape and Summarize Webpages with AI

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| manualTrigger | N/A | HTTP, OpenAI | gpt-4o-mini | N/D | title, summary, url | content | Limita a 3 ensayos; chunkSize=6000; extracción HTML selectiva |

### Metadata for RAG — Scrape and Summarize Webpages with AI

```json
{
  "name": "Scrape and Summarize Webpages with AI",
  "source_url": "https://n8n.io/workflows/1951-scrape-and-summarize-webpages-with-ai/",
  "repo_path": "workflow_templates/json/Scrape_and_summarize_webpages_with_AI.json",
  "nodes_count": 16,
  "triggers": ["manualTrigger"],
  "connectors": ["http", "openai"],
  "timezone": "N/D",
  "outputs": ["title", "summary", "url"],
  "domain": "content",
  "last_updated_utc": "unknown"
}
```

### Reference — Scrape and Summarize Webpages with AI

Official workflow page on n8n: [https://n8n.io/workflows/1951-scrape-and-summarize-webpages-with-ai/](https://n8n.io/workflows/1951-scrape-and-summarize-webpages-with-ai/)
