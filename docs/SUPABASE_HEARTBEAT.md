# Supabase Heartbeat

CricStatz uses a scheduled GitHub Actions heartbeat to keep the Supabase free-tier project active during quiet periods.

## Why This Exists

Supabase free-tier projects can be paused after inactivity. The heartbeat performs a tiny read-only query twice per week so the backend receives light, intentional activity even when no one is using the app.

## What It Queries

The workflow queries `public.app_metrics`, which is already used by the website metrics code and contains non-sensitive app counters.

The request is equivalent to:

```http
GET /rest/v1/app_metrics?select=key_name&key_name=eq.total_downloads&limit=1
```

This returns at most one row and does not insert, update, delete, or call any mutating RPC.

## Schedule

The workflow runs twice per week:

- Monday at 04:17 UTC
- Thursday at 04:17 UTC

It can also be run manually from the GitHub Actions tab through `workflow_dispatch`.

## Required GitHub Secrets

Create these repository secrets in GitHub:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Use the project URL and anon public API key from the Supabase project settings. Do not commit these values into the workflow file.

## How To Disable

To disable the heartbeat, either:

- Disable the `Supabase Heartbeat` workflow in the GitHub Actions UI, or
- Remove/comment the `schedule` block in `.github/workflows/supabase-heartbeat.yml`, or
- Delete `.github/workflows/supabase-heartbeat.yml`.

Manual runs will still be available if `workflow_dispatch` remains in the file.

## Security Notes

The heartbeat uses only a bounded `GET` request with `limit=1`. It targets a non-sensitive metrics table and stores credentials only in GitHub Secrets. The workflow has `contents: read` permissions and does not check out or modify repository files.
