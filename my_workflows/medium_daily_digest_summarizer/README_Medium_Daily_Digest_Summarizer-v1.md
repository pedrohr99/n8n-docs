# Medium Daily Digest Summarizer — Updated README

## What it does

- Runs daily at 09:30 (workflow timezone), fetches the latest Medium Daily Digest from Gmail, extracts article links, calls a child workflow to summarize them in Spanish, and sends a clean HTML email with titles, summaries, and a “Read on Medium” button.
- Implements strict Medium URL cleaning/deduplication, paywall-aware handling with a user warning, automatic retry if the model doesn’t return valid JSON, and visual “ATENCIÓN:” highlighting in the email body for limited-content cases.

## Key changes vs prior version

- Replaced “generate Markdown + upload to Google Drive” with “generate HTML + send via Gmail” for instant delivery and better mobile/desktop reading.
- Added visual warning highlighting via highlightAttention during HTML assembly, styling any “ATENCIÓN: …” in the translated summary for maximum visibility in Gmail.
- Modular architecture with child workflow medium_articles_es_summary that encapsulates fetch, parse, and strict JSON summarization, with paywall heuristics and batching/timeout for robustness.

## Prerequisites

- n8n 1.x running (Cloud or self‑hosted/Docker) and correct workflow timezone if different from the global instance setting.
- Gmail OAuth2 credentials configured in n8n to read and send emails with the same account.
- OpenAI credential configured in n8n for the child workflow (chat completions with JSON-only response).
- Subscription to Medium Daily Digest and delivery from <noreply@medium.com>.

## Installation

- Import medium_daily_digest_summarizer-v1.json and medium_articles_es_summary-v1.json into n8n and save both workflows.
- In the parent workflow, select Gmail credentials on “Gmail Get Digest” and “Gmail Send Digest,” and keep or adjust the “Schedule Trigger” to the desired time (JSON ships with 09:30).
- In the child workflow, select the OpenAI credential on “OpenAI Chat (JSON)” and test with a sample Medium URL to verify parsing/summarization.

## Architecture

- Schedule Trigger → Gmail Get Digest → Clean HTML → Extract Medium Links → Filter & Dedup Links → Execute Sub‑workflow → Needs Retry? → (True: Wait 3s → Execute Sub‑workflow) → Assemble HTML → Gmail Send Digest.
- Child workflow: Execute Workflow Trigger → Fetch Medium HTML → Parse Reader Markdown → OpenAI Chat (JSON) → Parse OpenAI JSON → Shape Output → returns title/title_translate/summary_translate/url.

## Nodes and config (parent)

- Schedule Trigger: runs daily at 09:30; actual timezone is the workflow’s (falls back to instance timezone if unset).
- Gmail Get Digest: operation getAll, limit 5, simple=false, filters q: “newer_than:1d”, sender: “<noreply@medium.com>” to retrieve the digest’s full HTML.
- Clean HTML (Code): unescapes quotes and slashes so CSS extraction works reliably.
- Extract Medium Links (HTML): operation extractHtmlContent, dataPropertyName=html, extracts all `<a href>` into “urls” as an array.
- Filter & Dedup Links (Code): removes unsubscribe/help/privacy links, enforces domain “<https://medium.com/@…”>, strips query params “?” and “----…” suffixes, and deduplicates keeping only 3‑segment paths.
- Execute Sub‑workflow: calls medium_articles_es_summary and waits for a response per URL (waitForSubWorkflow=true), retrieving original title, Spanish title, Spanish summary, and URL; a downstream retry handles missing data.
- Needs Retry? (IF): retries when title_translate is empty, summary_translate is empty, or summary_translate equals “El modelo no devolvió JSON parseable.”, using OR combinator.
- Wait 3s: short pause before re‑calling the child workflow on the same item, to mitigate transient HTTP/model issues.
- Assemble HTML (Code): builds a minimal responsive email with h1/h2/h3, “Read on Medium” button, and highlightAttention to style any “ATENCIÓN: …” in the summary.
- Gmail Send Digest: sends the HTML email to the configured recipient with the subject and html built in the prior step, without extra attribution.

## Nodes and config (child)

- When executed by another node: exposes the child workflow to be invoked by the parent and receive the URL.
- Fetch Medium HTML (HTTP Request): fetches Reader view via r.jina.ai/http://{host/path}, sets a normal browser User‑Agent, batching 1 item every 3s with 90s timeout for stability.
- Parse Reader Markdown (Code): extracts Title, prefers canonical URL via the “Sign in” redirect (decoded) or falls back to “URL Source,” slices out “Markdown Content,” normalizes spacing, and flags paywalled content via heuristics.
- OpenAI Chat (JSON) (HTTP Request): calls /v1/chat/completions with model “gpt-5-mini”, response_format json_object, and a conditional prompt: when paywalled, it enforces a warning suffix “ATENCIÓN: Resumen limitado por falta de login”.
- Parse OpenAI JSON (Code): parses choices.message.content into an object; on failure, sets “El modelo no devolvió JSON parseable.” and re‑combines title/URL by index from the prior parse step.
- Shape Output (Set): outputs title, title_translate, summary_translate, url as flat fields for consumption by the parent.

## Design rationale

- Separation of concerns: parent handles email, extraction, and delivery; child encapsulates scraping, parsing, and summarization, enabling easier testing and scaling without breaking the main flow.
- Digest HTML resilience: pre‑cleaning HTML plus CSS selector extraction reduces dependency on email markup quirks and avoids ad‑hoc decoding in downstream nodes.
- Canonical, noise‑free URLs: enforcing “<https://medium.com/@…”> and stripping tracking/extra parts ensures the child receives valid post URLs and avoids duplicate/model waste.
- Paywall‑aware summaries: when content is limited, the child returns a prudent Spanish summary with an explicit “ATENCIÓN” suffix, which is later visually highlighted in the email.
- Bounded retries: validating empty/invalid JSON fields with a short wait prevents infinite loops and reduces API pressure while recovering from transient failures.

## How to run

1) Import both JSONs and assign credentials: Gmail in the two parent nodes and OpenAI in the child.
2) Adjust Gmail Get Digest filters (e.g., different sender/time window or higher “limit”) and the final recipient in Gmail Send Digest.
3) Manually execute the parent to validate the end‑to‑end path with a recent digest and preview the HTML output before enabling the schedule.
4) Activate the workflow and confirm the timezone is configured so the trigger fires at 09:30 local time as intended.

## Customization

- Timing/frequency: change “Schedule Trigger” to another time or weekdays/weekends pattern.
- Number of articles: tweak Gmail Get Digest limit or shrink after “Filter & Dedup Links” to control the volume.
- Recipients: adjust “sendTo” in Gmail Send Digest for teams, lists, or aliases.
- Email style: modify fonts/colors/button and the highlightAttention function to match brand and warning emphasis.
- Model/tone: in the child, swap models or refine JSON instructions to alter length or style of the Spanish summary.

## Handy snippets

- Gmail Get Digest filters:

```json
{
  "node": "Gmail Get Digest",
  "parameters": {
    "operation": "getAll",
    "limit": 5,
    "simple": false,
    "filters": { "q": "newer_than:1d", "sender": "noreply@medium.com" }
  }
}
```

- Medium link cleanup/dedup:

```js
// Keep only https://medium.com/@... and drop tracking/extra parts
if (!url.startsWith('https://medium.com/@')) continue;
let cleanUrl = url.split('?');
cleanUrl = cleanUrl.replace(/----.*$/, '');
const parts = cleanUrl.replace('https://', '').split('/');
if (parts.length === 3) /* push unique cleanUrl */;
```

- Visual “ATENCIÓN:” highlighting in email:

```js
function highlightAttention(text = '') {
  const re = /(ATENCI[ÓO]N:\s*.*)$/gim;
  const attStyle = "color:#D92D20;font-weight:600;background:#FEF3F2;padding:0 6px;border-radius:6px";
  return text.replace(re, (m) => `<span style="${attStyle}">${m}</span>`);
}
```

- Child prompt (paywalled branch):

```json
{
  "response_format": {"type": "json_object"},
  "messages": [
    {"role": "system", "content": "Eres un redactor técnico y respondes SOLO JSON válido."},
    {"role": "user", "content": "... Devuelve SOLO este objeto JSON: {\"title_translate\":\"…\",\"summary_translate\":\"… Al final SIEMPRE añade: ATENCIÓN: Resumen limitado por falta de login\"}"}
  ]
}
```

## Common issues and fixes

- “No digest emails found”: verify subscription, Gmail Get Digest filters, and that a digest arrived in the last 24h; temporarily widen the window/limit for testing.
- “Empty summary_translate or invalid JSON”: automatic retry kicks in; if it persists, check the child’s OpenAI credential/model or increase HTTP timeout/waits between items.
- “Paywalled with too little text”: the child returns a cautious summary with “ATENCIÓN,” by design; to improve, raise batchInterval/timeout or alter the extraction source.
- “Email sent but no styles”: ensure Gmail Send Digest uses message=html and that Assemble HTML returns a properly formed html field.

## Best practices used

- CSS extraction with pre‑sanitized HTML to minimize markup brittleness from email bodies.
- URL cleanup/dedup before hitting the model to save tokens and avoid duplicates.
- Child workflow returns strict JSON with defensive parsing to absorb occasional model deviations.
- Batching + intervals + realistic timeouts to avoid blocking when fetching articles.

## Activation and maintenance

- Activate the parent workflow after manual tests and monitor initial runs to confirm article volume and proper email rendering.
- Version changes to Code nodes and child prompts, and document filter/schedule edits in workflow history for traceability.

## Credits and compatibility

- Designed for n8n 1.x, using core nodes (Gmail/HTTP/HTML/IF/Wait/Code) and a child workflow that calls OpenAI via HTTP Request—no community nodes required.
- The previous README is updated to reflect Gmail HTML sending instead of Drive file creation, while keeping the daily schedule and Medium digest concept intact.
