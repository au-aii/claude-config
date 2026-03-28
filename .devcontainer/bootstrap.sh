#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_STRICT="${BOOTSTRAP_STRICT:-0}"
SKIP_NPM_INSTALL="${SKIP_NPM_INSTALL:-0}"
SKIP_PLAYWRIGHT="${PLAYWRIGHT_SKIP_INSTALL:-0}"
SKIP_HUSKY="${SKIP_HUSKY_SETUP:-0}"

log() {
  echo "[bootstrap] $1"
}

warn() {
  echo "[bootstrap] Warning: $1"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

fail_or_warn() {
  local message="$1"
  if [[ "$BOOTSTRAP_STRICT" == "1" ]]; then
    echo "[bootstrap] Error: $message"
    exit 1
  fi
  warn "$message"
}

log "Starting comprehensive bootstrap..."

# 1) Check essential commands.
missing_commands=()
for cmd in git node npm npx; do
  if ! has_command "$cmd"; then
    missing_commands+=("$cmd")
  fi
done

if [[ ${#missing_commands[@]} -gt 0 ]]; then
  fail_or_warn "Missing required commands: ${missing_commands[*]}"
else
  log "Required commands available: git node npm npx"
fi

if ! has_command rsync; then
  warn "rsync is not available. Template copy step in README uses rsync."
fi

if ! has_command claude; then
  warn "claude CLI is not available in this environment."
fi

# 2) Install npm dependencies.
if [[ "$SKIP_NPM_INSTALL" != "1" ]] && [[ -f package.json ]]; then
  if [[ -f package-lock.json ]]; then
    log "Installing npm dependencies with npm ci..."
    npm ci || fail_or_warn "npm ci failed"
  else
    log "Installing npm dependencies with npm install..."
    npm install || fail_or_warn "npm install failed"
  fi
fi

# 3) Setup Husky if configured.
if [[ "$SKIP_HUSKY" != "1" ]] && [[ -d .husky ]] && [[ -f package.json ]]; then
  if grep -q '"husky"' package.json; then
    log "Initializing Husky hooks..."
    npx husky install || warn "Husky initialization failed."
  else
    warn ".husky exists but husky dependency is not found in package.json."
  fi
fi

# 4) MCP-related setup.
if [[ -f mcp_config.json ]]; then
  if grep -q "@playwright/mcp" mcp_config.json; then
    if [[ "$SKIP_PLAYWRIGHT" != "1" ]]; then
      log "Playwright MCP detected. Installing Chromium..."
      npx -y playwright install chromium || warn "Playwright Chromium install failed. Run manually if needed."
    else
      log "Skipping Playwright install (PLAYWRIGHT_SKIP_INSTALL=1)."
    fi
  fi

  if grep -q "@upstash/context7-mcp" mcp_config.json; then
    if grep -q "REPLACE_ME_OR_SET_ENV" mcp_config.json; then
      warn "Context7 placeholders are still present in mcp_config.json."
    fi
    if [[ -z "${UPSTASH_REDIS_REST_URL:-}" || -z "${UPSTASH_REDIS_REST_TOKEN:-}" ]]; then
      warn "UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN are not set in current shell."
    fi
  fi
fi

log "Bootstrap completed."
