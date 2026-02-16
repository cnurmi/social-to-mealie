# MiniMax Provider Integration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add MiniMax as a selectable text-generation provider for recipe extraction, alongside the existing OpenAI-compatible provider.

**Architecture:** A new `TEXT_PROVIDER` env var selects which provider handles recipe generation (`openai` default, `minimax` new). Transcription (Whisper) remains on the OpenAI path unchanged. `ai.ts` lazily selects the model at call time based on the env var using the `vercel-minimax-ai-provider` community package.

**Tech Stack:** `vercel-minimax-ai-provider`, Vercel AI SDK (`ai`), Next.js, TypeScript

---

### Task 1: Install the MiniMax provider package

**Files:**
- Modify: `package.json` (via npm)

**Step 1: Install the package**

```bash
npm install vercel-minimax-ai-provider
```

**Step 2: Verify it appears in package.json**

```bash
grep minimax package.json
```

Expected output includes: `"vercel-minimax-ai-provider"`

**Step 3: Commit**

```bash
git add package.json package-lock.json
git commit -m "feat: add vercel-minimax-ai-provider dependency"
```

---

### Task 2: Add new env var types

**Files:**
- Modify: `src/lib/types.ts`

**Step 1: Add fields to `envTypes`**

In `src/lib/types.ts`, add two fields to the `envTypes` object (after `TEXT_MODEL`):

```ts
TEXT_PROVIDER: string;    // "openai" | "minimax", defaults to "openai"
MINIMAX_API_KEY: string;  // required when TEXT_PROVIDER=minimax
```

Result should look like:

```ts
export type envTypes = {
    OPENAI_URL: string;
    OPENAI_API_KEY: string;
    TRANSCRIPTION_MODEL: string;
    TEXT_MODEL: string;
    TEXT_PROVIDER: string;
    MINIMAX_API_KEY: string;
    MEALIE_URL: string;
    MEALIE_API_KEY: string;
    MEALIE_GROUP_NAME: string;
    FFMPEG_PATH: string;
    YTDLP_PATH: string;
    EXTRA_PROMPT: string;
    COOKIES: string;
    LOCAL_TRANSCRIPTION_MODEL: string;
};
```

**Step 2: Commit**

```bash
git add src/lib/types.ts
git commit -m "feat: add TEXT_PROVIDER and MINIMAX_API_KEY to envTypes"
```

---

### Task 3: Read new env vars in constants

**Files:**
- Modify: `src/lib/constants.ts`

**Step 1: Add the two new fields** (after the `TEXT_MODEL` line):

```ts
TEXT_PROVIDER: process.env.TEXT_PROVIDER?.trim() || "openai",
MINIMAX_API_KEY: process.env.MINIMAX_API_KEY?.trim() || "",
```

Result should look like:

```ts
export const env: envTypes = {
    OPENAI_URL: process.env.OPENAI_URL?.trim().replace(/\/+$/, "") as string,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY?.trim() as string,
    TRANSCRIPTION_MODEL: (
        process.env.TRANSCRIPTION_MODEL || process.env.TRANSCRIPTION_MODEL
    )?.trim() as string,
    TEXT_MODEL: process.env.TEXT_MODEL?.trim() as string,
    TEXT_PROVIDER: process.env.TEXT_PROVIDER?.trim() || "openai",
    MINIMAX_API_KEY: process.env.MINIMAX_API_KEY?.trim() || "",
    MEALIE_URL: process.env.MEALIE_URL?.trim().replace(/\/+$/, "") as string,
    MEALIE_API_KEY: process.env.MEALIE_API_KEY?.trim().replace(/\n/g, "") as string,
    MEALIE_GROUP_NAME: process.env.MEALIE_GROUP_NAME?.trim() || ("home" as string),
    FFMPEG_PATH: process.env.FFMPEG_PATH?.trim() || ("/usr/bin/ffmpeg" as string),
    YTDLP_PATH: process.env.YTDLP_PATH?.trim() || ("./yt-dlp" as string),
    EXTRA_PROMPT: process.env.EXTRA_PROMPT?.trim() || ("" as string),
    COOKIES: process.env.COOKIES?.trim() || ("" as string),
    LOCAL_TRANSCRIPTION_MODEL: process.env.LOCAL_TRANSCRIPTION_MODEL?.trim() || ("" as string),
};
```

**Step 2: Commit**

```bash
git add src/lib/constants.ts
git commit -m "feat: read TEXT_PROVIDER and MINIMAX_API_KEY from env"
```

---

### Task 4: Wire MiniMax into ai.ts

**Files:**
- Modify: `src/lib/ai.ts`

**Step 1: Add the MiniMax import** at the top of the file, after the existing imports:

```ts
import { createMinimax } from "vercel-minimax-ai-provider";
```

**Step 2: Remove the module-level `textModel` constant**

Delete this line:
```ts
const textModel = client.chat(env.TEXT_MODEL);
```

**Step 3: Add a `getTextModel()` helper** after the `transcriptionModel` line:

```ts
function getTextModel() {
    if (env.TEXT_PROVIDER === "minimax") {
        const minimaxClient = createMinimax({ apiKey: env.MINIMAX_API_KEY });
        return minimaxClient(env.TEXT_MODEL);
    }
    return client.chat(env.TEXT_MODEL);
}
```

**Step 4: Update `generateRecipeFromAI` to call `getTextModel()`**

Inside `generateRecipeFromAI`, change:
```ts
const { object } = await generateObject({
    model: textModel,
```
to:
```ts
const { object } = await generateObject({
    model: getTextModel(),
```

**Step 5: Verify the build compiles**

```bash
npm run build
```

Expected: no TypeScript errors. Fix any import issues if they appear (check the exact export name from `vercel-minimax-ai-provider` with `node -e "console.log(Object.keys(require('vercel-minimax-ai-provider')))"` if needed).

**Step 6: Commit**

```bash
git add src/lib/ai.ts
git commit -m "feat: support MiniMax as text provider in ai.ts"
```

---

### Task 5: Document in example.env

**Files:**
- Modify: `example.env`

**Step 1: Append a MiniMax section** at the end of `example.env`:

```env

# --- MiniMax provider (alternative to OpenAI for recipe generation) ---
# Set TEXT_PROVIDER=minimax and supply your MiniMax API key.
# Get your key at https://platform.minimax.io
# Available models: MiniMax-M2, MiniMax-M2-Stable
# TEXT_PROVIDER=minimax
# MINIMAX_API_KEY=your-key-here
# TEXT_MODEL=MiniMax-M2
```

**Step 2: Commit**

```bash
git add example.env
git commit -m "docs: document MiniMax provider configuration in example.env"
```

---

### Task 6: Verify end-to-end (manual smoke test)

No automated tests exist in this project. Verify manually:

**Step 1: Build the Docker image**

```bash
docker compose build
```

Expected: build succeeds with no errors.

**Step 2: Confirm the OpenAI path still works**

Start the app with your existing `.env` (no `TEXT_PROVIDER` set). Submit a recipe URL. Confirm it extracts correctly — this proves the default path is unbroken.

**Step 3: Confirm the MiniMax path works**

Add to your `.env`:
```
TEXT_PROVIDER=minimax
MINIMAX_API_KEY=<your key>
TEXT_MODEL=MiniMax-M2
```

Restart and submit a recipe URL. Confirm recipe extraction completes successfully.
