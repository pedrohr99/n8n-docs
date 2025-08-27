# Index of n8n workflow templates

This document indexes the n8n workflow JSON templates present in this repository. It provides operational metadata and a "Metadata for RAG" block to facilitate ingestion into a Retrieval-Augmented Generation (RAG) system and ChatLLM training.

## Table of Contents

- [Email_Summary_Agent.json — Email Summary Agent](#email_summary_agentjson--email-summary-agent)
- [Gmail_AI_Email_Manager.json — Email Manager](#gmail_ai_email_managerjson--email-manager)
- [Intelligent_Email_Organization_AI_Content_Classification_Gmail.json — Auto Gmail Labeling (Powered by OpenAI)](#intelligent_email_organization_ai_content_classification_gmailjson--auto-gmail-labeling-powered-by-openai)
- [Automate_Email_Calendar_Management_Gmail_Google_Calendar_GPT-4o.json — [AOE]  Inbox & Calendar Management Agent](#automate_email_calendar_management_gmail_google_calendar_gpt-4ojson--aoe-inbox-&-calendar-management-agent)
- [Analyze_Sort_Suspicious_Email_Contents_ChatGPT.json — Analyze and Sort Suspicious Email Contents (ChatGPT)](#analyze_sort_suspicious_email_contents_chatgptjson--analyze-and-sort-suspicious-email-contents-chatgpt)
- [Screen_Score_Resumes_Gmail_Sheets_AI.json — Resume Screener from Gmail to Sheets](#screen_score_resumes_gmail_sheets_aijson--resume-screener-from-gmail-to-sheets)

## Email_Summary_Agent.json — Email Summary Agent

### Functional summary — Email Summary Agent

- Displaces daily at 07:00 (Schedule Trigger) in the Asia/Kolkata timezone.
- Retrieves all emails from the past 24 hours using the Gmail node with a dynamic filter (query `after:YYYY/MM/DD` calculated for yesterday) for the account `isb.quantana@quantana.in`.
- Aggregates and structures key fields (id, From, To, CC, snippet) before inference.
- Produces a structured summary (JSON) using an OpenAI model (gpt-4o-mini) based on the aggregated data.
- Sends an HTML report email containing the summary and action items, using a dynamic subject line with a date range.

### Metadata — Email Summary Agent

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Notes |
|----------|-----------|--------------|------------|----------|---------|-------|
| scheduleTrigger | Daily 07:00 | Gmail, OpenAI | gpt-4o-mini | Asia/Kolkata | HTML (email), JSON (LLM summary) | Gmail filter for last 24h; aggregated fields: id, From, To, CC, snippet; dynamic subject line |

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
  "last_updated_utc": "N/D"
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

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Notes |
|----------|-----------|--------------|------------|----------|---------|-------|
| gmailTrigger | poll everyMinute | Gmail, Anthropic | claude-sonnet-4-20250514 | N/D | structured JSON (contains `label ID`); Gmail addLabels operation | Uses AI agent with system message for labeling; Get Email and Check Sent use `from`/`to` filters via `$fromAI('email')`; credentials are redacted |

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
  "last_updated_utc": "N/D"
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

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Notes |
|----------|-----------|--------------|------------|----------|---------|-------|
| scheduleTrigger | Every 2 minutes | Gmail, OpenAI | gpt-4.1-nano | N/D | Gmail addLabels, created label, structured JSON (AI output) | Uses Filter Emails Without Excluded Labels; limit=20 on initial fetch; splitInBatches for processing; credentials present but redacted |

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
  "last_updated_utc": "N/D"
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

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Notes |
|----------|-----------|--------------|------------|----------|---------|-------|
| chatTrigger, executeWorkflowTrigger, manualTrigger, gmailTrigger | N/D | Gmail, Google Calendar, OpenAI | gpt-4o, gpt-4o-mini, gpt-4.1-mini | N/D | email drafts, deleted emails, calendar events, embeddings/vectorstore entries, summarized thread text | Uses window buffer memory, embeddings and vector store; multiple Gmail and Google Calendar tool nodes; credentials redacted |

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
  "last_updated_utc": "N/D"
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

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Notes |
|----------|-----------|--------------|------------|----------|---------|-------|
| gmailTrigger, microsoftOutlookTrigger (disabled) | Every minute | Gmail, Microsoft Outlook (Graph), hcti.io (HTTP), OpenAI, Jira | gpt-4o | N/D | jira_ticket_malicious, jira_ticket_benign, email_screenshot (PNG), email_body.txt, json_analysis | Uses Microsoft Graph to retrieve headers, uses hcti.io to render HTML screenshots, OpenAI node returns JSON (jsonOutput=true) |

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
  "last_updated_utc": "N/D"
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

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Notes |
|----------|-----------|--------------|------------|----------|---------|-------|
| gmailTrigger | Every hour (minute 1) | Gmail, Google Sheets, OpenAI | gpt-4o-mini | N/D | Google Sheets row (append), extracted resume text, structured JSON (name, email, linkedin, score) | Trigger filters: `has:attachment`, `labelIds: [UNREAD]`; extracts PDF attachments and uses Structured Output Parser; credentials are present but redacted |

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
  "last_updated_utc": "N/D"
}
```

### Reference — Resume Screener from Gmail to Sheets

Official workflow page on n8n: [https://n8n.io/workflows/3546-screen-and-score-resumes-from-gmail-to-sheets-with-ai/](https://n8n.io/workflows/3546-screen-and-score-resumes-from-gmail-to-sheets-with-ai/)
