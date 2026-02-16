# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Overview

Fork of [GerardPolloRebozado/social-to-mealie](https://github.com/GerardPolloRebozado/social-to-mealie).
Extracts recipes from social media URLs (via yt-dlp + Whisper transcription) and imports them into Mealie.

Custom additions in this fork:
- MiniMax as a selectable text provider (via `TEXT_PROVIDER=minimax`)

## Tech Stack

- Next.js 16, TypeScript, Vercel AI SDK (`ai` v5)
- `@ai-sdk/openai` for both OpenAI-compatible and MiniMax requests
- `@huggingface/transformers` for local Whisper transcription
- Node.js ≥ 18 required (WSL default is v12 — use `nvm use 22`)

## AI Provider Configuration

### MiniMax (active in production)
```
TEXT_PROVIDER=minimax
TEXT_MODEL=MiniMax-M2
MINIMAX_API_KEY=<key>   # or Docker secret: minimax_api_key
```
MiniMax uses OpenAI-compatible API at `https://api.minimax.io/v1` via `@ai-sdk/openai`.
The community package `vercel-minimax-ai-provider` was tried and dropped — it uses Anthropic
format by default, which was incompatible. Direct `createOpenAI({ baseURL })` works reliably.

### OpenAI (default)
```
TEXT_PROVIDER=openai   # or omit — this is the default
OPENAI_URL=https://api.openai.com/v1
OPENAI_API_KEY=<key>
TEXT_MODEL=gpt-4o-mini
```

## Deployment (mediasrv)

This repo is deployed on `mediasrv` via the homeserver Docker Compose stack.

**Source on mediasrv:** `/home/cnurmi/repo/social-to-mealie`
**Compose file:** `/home/cnurmi/docker/compose/mediasrv/social-to-mealie.yml`
**URL:** `https://recipes.nurhome.xyz`

### Deploy workflow
```bash
# 1. Make and commit changes locally
git push origin main

# 2. On mediasrv — pull latest source
git -C /home/cnurmi/repo/social-to-mealie pull

# 3. Rebuild and restart (run on mediasrv or via SSH)
cd /home/cnurmi/docker
docker compose -f docker-compose-mediasrv.yml build social-to-mealie
docker compose -f docker-compose-mediasrv.yml up -d social-to-mealie
```

### Secrets
Two Docker secrets are required:
- `/home/cnurmi/docker/secrets/minimax_api_key` — MiniMax API key
- `/home/cnurmi/docker/secrets/mealie_api_key` — Mealie API token

**Permissions must be 644** (not 600). The container runs as `nextjs` (non-root) and bind-mounted
secret files must be world-readable.

```bash
chmod 644 /home/cnurmi/docker/secrets/minimax_api_key
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
