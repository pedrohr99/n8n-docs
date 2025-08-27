# Index of n8n workflow templates

This document indexes the n8n workflow JSON templates present in this repository. It provides operational metadata and a "Metadata for RAG" block to facilitate ingestion into a Retrieval-Augmented Generation (RAG) system and ChatLLM training.

## Table of Contents

- [Email_Summary_Agent.json — Email Summary Agent](#email_summary_agentjson--email-summary-agent)

## Email_Summary_Agent.json — Email Summary Agent

### Functional summary

- Triggers daily at 07:00 (Schedule Trigger) in the Asia/Kolkata timezone.
- Retrieves all emails from the past 24 hours using the Gmail node with a dynamic filter (query `after:YYYY/MM/DD` calculated for yesterday) for the account `isb.quantana@quantana.in`.
- Aggregates and structures key fields (id, From, To, CC, snippet) before inference.
- Produces a structured summary (JSON) using an OpenAI model (gpt-4o-mini) based on the aggregated data.
- Sends an HTML report email containing the summary and action items, using a dynamic subject line with a date range.

### Metadata

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Notes |
|----------|-----------|--------------|------------|----------|---------|-------|
| scheduleTrigger | Daily 07:00 | Gmail, OpenAI | gpt-4o-mini | Asia/Kolkata | HTML (email), JSON (LLM summary) | Gmail filter for last 24h; aggregated fields: id, From, To, CC, snippet; dynamic subject line |

### Metadata for RAG

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

### Reference

Official workflow page on n8n: [https://n8n.io/workflows/2722-email-summary-agent/](https://n8n.io/workflows/2722-email-summary-agent/)
