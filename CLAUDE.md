# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Overview

Fork of [GerardPolloRebozado/social-to-mealie](https://github.com/GerardPolloRebozado/social-to-mealie).
Extracts recipes from social media URLs (via yt-dlp + Whisper transcription) and imports them into Mealie.

Custom additions in this fork:

- MiniMax as a selectable text provider (via `TEXT_PROVIDER=minimax`)
- Groq as a selectable text provider (via `TEXT_PROVIDER=groq`)

## Tech Stack

- Next.js 16, TypeScript, Vercel AI SDK (`ai` v5)
- `@ai-sdk/openai` for OpenAI-compatible providers (OpenAI, MiniMax, Groq)
- `@huggingface/transformers` for local Whisper transcription
- Node.js ≥ 18 required (WSL default is v12 — use `nvm use 22`)

## AI Provider Configuration

### Groq (active in production)

```env
TEXT_PROVIDER=groq
TEXT_MODEL=llama-3.3-70b-versatile
GROQ_API_KEY=<key>   # or Docker secret: groq_api_key
```

Groq uses an OpenAI-compatible API at `https://api.groq.com/openai/v1` via `@ai-sdk/openai`.
Free tier available at [console.groq.com](https://console.groq.com). Budget alternative: `llama-3.1-8b-instant`.

### MiniMax (supported, not in production)

```env
TEXT_PROVIDER=minimax
TEXT_MODEL=MiniMax-M2
MINIMAX_API_KEY=<key>   # or Docker secret: minimax_api_key
```

MiniMax uses OpenAI-compatible API at `https://api.minimax.io/v1` via `@ai-sdk/openai`.
Note: `sk-cp-` (coding plan) keys do NOT work — only PAYG `sk-api-` keys work.
The community package `vercel-minimax-ai-provider` was tried and dropped — incompatible format.

### OpenAI (default)

```env
TEXT_PROVIDER=openai   # or omit — this is the default
OPENAI_URL=https://api.openai.com/v1
OPENAI_API_KEY=<key>
TEXT_MODEL=gpt-4o-mini
```

## Deployment (mediasrv)

This repo is deployed on `mediasrv` via the homeserver Docker Compose stack.

**Image registry:** `ghcr.io/cnurmi/social-to-mealie:latest`
**Compose file:** `/home/cnurmi/docker/compose/mediasrv/social-to-mealie.yml`
**URL:** `https://recipes.nurhome.xyz`

### Deploy workflow

Push to `main` triggers GitHub Actions (`.github/workflows/build-registry.yml`) to build
the Docker image and push it to `registry.nurhome.xyz`. Mediasrv then just pulls and restarts
— no local build required.

```bash
# 1. Make, commit, and push changes locally — this triggers the CI build
git push origin main

# 2. Wait for GitHub Actions to finish (~3-5 min first time, faster with GHA cache)
#    Check: https://github.com/cnurmi/social-to-mealie/actions

# 3. On mediasrv — pull new image and restart (seconds)
cd /home/cnurmi/docker
docker compose -f docker-compose-mediasrv.yml pull social-to-mealie
docker compose -f docker-compose-mediasrv.yml up -d social-to-mealie
```

### GitHub Actions setup (one-time)

Add these as repository secrets at `Settings > Secrets > Actions`:

- `REGISTRY_USERNAME` — login for `registry.nurhome.xyz`
- `REGISTRY_PASSWORD` — password for `registry.nurhome.xyz`

### Secrets

Two Docker secrets are required on mediasrv:

- `/home/cnurmi/docker/secrets/groq_api_key` — Groq API key
- `/home/cnurmi/docker/secrets/mealie_api_key` — Mealie API token

**Permissions must be 644** (not 600). The container runs as `nextjs` (non-root) and bind-mounted
secret files must be world-readable.

```bash
chmod 644 /home/cnurmi/docker/secrets/groq_api_key
chmod 644 /home/cnurmi/docker/secrets/mealie_api_key
```

## Key Files

- `src/lib/ai.ts` — provider selection, transcription, recipe generation
- `src/lib/constants.ts` — reads all env vars
- `src/lib/types.ts` — `envTypes` type definition
- `entrypoint.sh` — loads Docker secret files into env vars at container start
- `example.env` — all supported env vars with documentation

## Local Development

```bash
# Requires Node 18+ — on WSL use nvm:
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm use 22

npm install
npm run dev
```
