#!/bin/sh
# entrypoint.sh
# Downloads yt-dlp at container startup if requested and ensures binary exists

set -e

# Load a Docker secret file into an environment variable.
# Usage: load_secret ENV_VAR_NAME secret_filename
load_secret() {
  local env_var="$1"
  local secret_file="/run/secrets/$2"
  if [ -f "$secret_file" ]; then
    export "$env_var=$(cat "$secret_file")"
  fi
}

load_secret MINIMAX_API_KEY minimax_api_key
load_secret GROQ_API_KEY groq_api_key
load_secret MEALIE_API_KEY mealie_api_key

YTDLP_BIN_PATH="${YTDLP_PATH:-./yt-dlp}"
YTDLP_VER="${YTDLP_VERSION:-}"

download_yt_dlp() {
  if [ -z "$YTDLP_VER" ] || [ "$YTDLP_VER" = "" ]; then
    echo "No YTDLP_VERSION provided; skipping yt-dlp download."
    return
  fi

  if [ -x "$YTDLP_BIN_PATH" ]; then
    echo "yt-dlp already present at $YTDLP_BIN_PATH"
    return
  fi

  if [ "$YTDLP_VER" = "latest" ]; then
    URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"
  else
    URL="https://github.com/yt-dlp/yt-dlp/releases/download/${YTDLP_VER}/yt-dlp"
  fi

  echo "Downloading yt-dlp ($YTDLP_VER) to $YTDLP_BIN_PATH"
  mkdir -p "$(dirname "$YTDLP_BIN_PATH")"
  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$YTDLP_BIN_PATH" "$URL" || {
      echo "Failed to download yt-dlp from $URL"
      return 1
    }
  elif command -v curl >/dev/null 2>&1; then
    curl -s -L -o "$YTDLP_BIN_PATH" "$URL" || {
      echo "Failed to download yt-dlp from $URL"
      return 1
    }
  else
    echo "Neither wget nor curl available to download yt-dlp"
    return 1
  fi

  chmod +x "$YTDLP_BIN_PATH"
  echo "yt-dlp downloaded and made executable"
}

# Try downloading if requested
download_yt_dlp || true

# exec the main process (passed as CMD)
exec "$@"
