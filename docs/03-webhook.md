# 03 — Webhook (event-driven CI trigger)

How the pipeline starts automatically when you push code — no human clicks "Build Now", no wasteful polling.

## The idea

Before webhooks: Jenkins **polled** GitHub every N minutes asking "any changes?" — wasteful, delayed.

With a webhook: GitHub **tells** Jenkins "hey, a push just happened" the moment it does. Event-driven = push-not-poll.

```
git push ──> GitHub ──HTTP POST──> Jenkins (http://16.113.34.59:8080/github-webhook/) ──> build runs
```

## Setup (2 sides)

**Jenkins side** (job config):
- Job → Configure → **Build Triggers** → tick **"GitHub hook trigger for GITScm polling"**.

**GitHub side** (repo settings):
- GitHub → repo → **Settings → Webhooks → Add webhook**:
  - **Payload URL:** `http://16.113.34.59:8080/github-webhook/`
  - **Content type:** `application/json`
  - **Events:** "Just the push event" (default)

## Why this works for us

- Jenkins must be **publicly reachable** — that's exactly what the **Elastic IP** provides (a stable public endpoint).
- Every `git push` to `main` now auto-triggers the full pipeline.

## Gold points

- Webhooks = event-driven (push-not-poll) — the modern CI pattern.
- The URL path `/github-webhook/` is Jenkins's built-in endpoint for GitHub hooks.
- Poll SCM (interval polling) is the old, wasteful alternative.
- The Jenkins **credential** `github-credentials` is used to *check out* the code; the webhook just *notifies* — two different mechanisms.
