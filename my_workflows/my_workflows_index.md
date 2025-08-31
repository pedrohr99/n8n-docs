# Index of n8n workflow templates

This document indexes the n8n workflow JSON templates present in this repository. It provides operational metadata and a "Metadata for RAG" block to facilitate ingestion into a Retrieval-Augmented Generation (RAG) system and ChatLLM training.

## Table of Contents

- [medium_daily_digest_summarizer-v1.json — Medium Daily Digest Summarizer](#medium_daily_digest_summarizer-v1json--medium-daily-digest-summarizer)
- [medium_articles_es_summary-v1.json — Medium Articles ES Summary](#medium_articles_es_summary-v1json--medium-articles-es-summary)

## medium_daily_digest_summarizer-v1.json — Medium Daily Digest Summarizer

### Functional summary — Medium Daily Digest Summarizer

- Runs daily at 09:30 (Schedule Trigger) to fetch the latest Medium Daily Digest email via Gmail.
- Extracts and cleans HTML, parses all Medium article links, then filters, normalizes, and deduplicates canonical post URLs.
- Invokes a child workflow per URL to fetch reader content and produce Spanish title & summary JSON (paywall-aware, JSON-only via OpenAI).
- Implements a retry branch when the child returns empty or invalid JSON fields (wait 3s, re-execute) to mitigate transient API errors.
- Assembles a styled HTML digest email (highlighting any ATENCIÓN warnings) and sends it via Gmail.

### Metadata — Medium Daily Digest Summarizer

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| scheduleTrigger | daily@09:30 | Gmail, OpenAI | gpt-5-mini | N/D | html_email | unknown | Child workflow summarization; retry on invalid JSON; highlights paywall warnings |

### Metadata for RAG — Medium Daily Digest Summarizer

```json
{
  "name": "Medium Daily Digest Summarizer",
  "source_url": "unknown",
  "repo_path": "medium_daily_digest_summarizer/medium_daily_digest_summarizer-v1.json",
  "nodes_count": 10,
  "triggers": ["schedule:daily@09:30"],
  "connectors": ["gmail", "openai"],
  "timezone": "N/D",
  "outputs": ["html_email"],
  "domain": "unknown",
  "last_updated_utc": "unknown"
}
```

### Reference — Medium Daily Digest Summarizer

- [Workflow JSON](medium_daily_digest_summarizer/medium_daily_digest_summarizer-v1.json)
- [Workflow README](medium_daily_digest_summarizer/README_Medium_Daily_Digest_Summarizer-v1.md)

## medium_articles_es_summary-v1.json — Medium Articles ES Summary

### Functional summary — Medium Articles ES Summary

- Exposed via Execute Workflow Trigger to be called per article URL by a parent workflow (no internal schedule).
- Builds a reader-friendly fetch URL, retrieves Medium article content, and extracts canonical title, URL (decoded), core Markdown, and paywall flag.
- Sends extracted content to OpenAI (gpt-5-mini) enforcing JSON-only Spanish title & summary output; adds warning suffix for paywalled items.
- Parses and validates model response, safely handling malformed JSON and aligning items by index.
- Outputs flat fields (title, title_translate, summary_translate, url) for downstream email/report assembly.

### Metadata — Medium Articles ES Summary

| Triggers | Schedules | Integrations | LLM Models | Timezone | Outputs | Domain | Notes |
|----------|-----------|--------------|------------|----------|---------|--------|-------|
| executeWorkflowTrigger | N/A | HTTP, OpenAI | gpt-5-mini | N/D | title, title_translate, summary_translate, url | unknown | Reader view fetch; paywall heuristic; 1-per-3s batching; JSON-only summarization |

### Metadata for RAG — Medium Articles ES Summary

```json
{
  "name": "Medium Articles ES Summary",
  "source_url": "unknown",
  "repo_path": "medium_articles_es_summary/medium_articles_es_summary-v1.json",
  "nodes_count": 6,
  "triggers": ["executeWorkflowTrigger"],
  "connectors": ["http", "openai"],
  "timezone": "N/D",
  "outputs": ["title", "title_translate", "summary_translate", "url"],
  "domain": "unknown",
  "last_updated_utc": "unknown"
}
```

### Reference — Medium Articles ES Summary

- [Workflow JSON](medium_articles_es_summary/medium_articles_es_summary-v1.json)
- [Workflow README](medium_articles_es_summary/README_Medium_Article_ES_Summary-v1.md)
