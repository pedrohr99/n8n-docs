# README_Medium_Article_ES_Summary-v1.md

## What it does

- Processes Medium article URLs passed in by a parent workflow, fetches a reader-friendly representation, and returns a Spanish title plus a 2–3 sentence Spanish summary as strict JSON fields for downstream use.
- Handles paywalled articles gracefully, flags them via heuristics, and enforces an “ATENCIÓN …” warning suffix in the summary for limited content so the parent can visually highlight it in email or UI.

## Prerequisites

- n8n 1.x with this workflow imported and set Inactive when used as a sub‑workflow, since it is designed to be invoked by Execute Workflow from a parent.
- An OpenAI credential configured in n8n and attached to the HTTP Request node named “OpenAI Chat (JSON)” to call the chat completions API with JSON-only responses.
- Network access for the reader endpoint used by “Fetch Medium HTML,” plus reasonable timeouts to accommodate article load variance and rate limits.

## Installation

- Import medium_articles_es_summary-v1.json into n8n, save, and keep it deactivated unless testing in isolation with pinned input items.
- Open “OpenAI Chat (JSON)” and select the valid OpenAI credential under Authentication to ensure requests succeed with the specified model and response format.
- No additional credentials are required for the HTTP fetch step, which uses a standard browser-like User-Agent header and batching/timeouts for stability.

## How it’s invoked

- The first node “When executed by another node” exposes this workflow for sub‑workflow execution, typically called per URL by a parent workflow using “Execute Workflow” with wait enabled.
- Expected input shape: each item must include a URL at json.url, for example: { "json": { "url": "<https://medium.com/@author/post-slug-id>" } }.
- Output shape per item: { "json": { "title": "...", "title_translate": "...", "summary_translate": "...", "url": "..." } }, optimized for the parent’s email assembly or persistence steps.

## Architecture

- Execute Workflow Trigger → Fetch Medium HTML → Parse Reader Markdown → OpenAI Chat (JSON) → Parse OpenAI JSON → Shape Output.
- The flow fetches reader content, extracts canonical title/URL and core Markdown, detects paywall conditions, and then calls the model to produce Spanish fields in strict JSON, with defensive parsing on the response.

## Nodes and configuration

- When executed by another node: exposes this workflow to be called by a parent and to receive URL input as items, without requiring its own schedule or external triggers.
- Fetch Medium HTML (HTTP Request): builds a reader-view URL from the incoming json.url, sets a desktop browser User‑Agent header, enables batching one item every 3 seconds, and uses a 90s timeout with retry and waitBetweenTries for robustness.
- Parse Reader Markdown (Code): parses the fetched Markdown to extract Title (Title: header, Setext H1, or ATX H1), derives a canonical URL from the Sign in redirect link or “URL Source,” normalizes the content body, trims overly long content, and flags paywall with regex heuristics.
- OpenAI Chat (JSON) (HTTP Request): posts a JSON-only prompt with model “gpt-5-mini,” temperature 1.0, low reasoning effort, and a conditional user message that enforces a warning suffix for paywalled cases while requesting Spanish title/summary fields.
- Parse OpenAI JSON (Code): attempts JSON.parse on choices.message.content, falls back to “El modelo no devolvió JSON parseable.” on error, and aligns indices with “Parse Reader Markdown” so title and URL remain consistent.
- Shape Output (Set): emits flat fields title, title_translate, summary_translate, and url to simplify downstream consumption by the parent workflow.

## Design rationale

- Reader-first fetch: using a reader-friendly representation increases consistency, reduces layout noise, and improves the reliability of plain text extraction for summarization prompts.
- Canonical URL detection: decoding the “Sign in” redirect ensures clean Medium post URLs, avoiding tracked or partial links that can cause duplicates or mis-routed clicks.
- Paywall heuristics: simple pattern checks mark limited content, which triggers a specific Spanish instruction so summaries are informative yet transparent about limitations.
- Strict JSON with guardrails: response_format json_object plus defensive parsing avoids brittle prompt-following issues and allows the parent to retry on empty/invalid content.

## How to test

- Pin a sample input item to “When executed by another node” with { "json": { "url": "<https://medium.com/@author/post-slug-id>" } } and execute the workflow to validate end‑to‑end output fields.
- Inspect “Parse Reader Markdown” output to ensure title/url/content/paywalled look correct, then review “OpenAI Chat (JSON)” and “Parse OpenAI JSON” for structured Spanish outputs.
- Confirm the final “Shape Output” fields match the expected schema before testing the parent workflow integration.

## Customization

- Model and tone: adjust model name, temperature, or the Spanish prompt snippets in “OpenAI Chat (JSON)” to change style or length while maintaining response_format json_object.
- Content length: tweak the 8000‑character cap in “Parse Reader Markdown” if summaries need more or less context passed to the model.
- Heuristics: refine the paywall regex or title extraction patterns if Medium’s output changes or new markers appear in the reader content.

## Handy snippets

- Expected input (per item)

```json
{
  "json": {
    "url": "https://medium.com/@author/post-slug-id"
  }
}
```

- Expected output (per item)

```json
{
  "json": {
    "title": "Original English title",
    "title_translate": "Título natural en español",
    "summary_translate": "Resumen en 2–3 frases en español (con ATENCIÓN… si paywall).",
    "url": "https://medium.com/@author/post-slug-id"
  }
}
```

- Reader-to-URL logic (conceptual)

```js
// Build a reader endpoint URL from incoming json.url, normalizing http/https
const readerUrl = readerHost + 'http://' + originalUrl.replace('https://','').replace('http://','');
```

## Common issues and fixes

- Empty or invalid JSON from model: the parser sets “El modelo no devolvió JSON parseable.” so the parent can retry with a short wait, which usually resolves transient API errors.
- Missing title: fallback logic sets “Sin título” if no Title/Setext/ATX H1 is detected in the reader content, which still allows summarization to proceed.
- Weak article text or paywalled: summaries remain cautious and include the “ATENCIÓN” suffix; consider lengthening timeouts or adjusting the reader fetch if content is consistently too sparse.
- Timeouts or rate limits: one-by-one batching with 3s interval, retries, and a 90s timeout mitigate most issues; tune intervals or timeout if encountering slow responses.

## Best practices used

- One-by-one batching to reduce server pressure and avoid throttling, with realistic timeouts for remote content.
- Canonical URL extraction to avoid duplicates and token waste in upstream/downstream steps.
- Defensive JSON parsing and index alignment to keep title/url consistent even when a model response is malformed.

## Activation and maintenance

- Keep this sub‑workflow Inactive by itself and invoke it from the parent with “Execute Workflow,” enabling “wait” so the parent can branch on success/failure conditions.
- Version any changes to the Code nodes and the prompt body in “OpenAI Chat (JSON),” and test with a few representative Medium articles (including paywalled) before rollout.

## Credits and compatibility

- Built for n8n 1.x using only core nodes (Execute Workflow Trigger, HTTP Request, Code, Set) and a standard HTTP call to an AI provider—no community nodes required.
- Designed to be paired with a parent workflow that extracts and deduplicates Medium links, orchestrates retries, and renders the final email or report.
