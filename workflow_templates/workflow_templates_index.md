# Index of n8n workflow templates

This document indexes the n8n workflow JSON templates present in this repository. It provides operational metadata and a "Metadata for RAG" block to facilitate ingestion into a Retrieval-Augmented Generation (RAG) system and ChatLLM training.

## Table of Contents

- [Email_Summary_Agent.json — Email Summary Agent](#email_summary_agentjson--email-summary-agent)
- [Gmail_AI_Email_Manager.json — Email Manager](#gmail_ai_email_managerjson--email-manager)

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
