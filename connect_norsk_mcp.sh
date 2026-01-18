#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  NORSK_USERNAME=... NORSK_PASSWORD=... ./connect_norsk_mcp.sh [--stay-open]

Optional environment variables:
  NORSK_AUTH_URL            Auth base URL (default: https://auth.liveencode.com)
  NORSK_STUDIO_URL          Studio base URL (default: https://studio.liveencode.com)
  NORSK_MCP_WS_URL           MCP WebSocket URL (default: wss://studio.liveencode.com/design-mcp)
  NORSK_TARGET_URL          Login target URL (default: ${NORSK_STUDIO_URL}/)
  NORSK_REQUEST_METHOD      Login request method (default: GET)
  NORSK_CONNECT_TIMEOUT_MS  WebSocket timeout in ms (default: 5000)

Flags:
  --stay-open               Keep WebSocket open after connect
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

stay_open=false
if [[ "${1:-}" == "--stay-open" ]]; then
  stay_open=true
fi

auth_url="${NORSK_AUTH_URL:-https://auth.liveencode.com}"
studio_url="${NORSK_STUDIO_URL:-https://studio.liveencode.com}"
ws_url="${NORSK_MCP_WS_URL:-wss://studio.liveencode.com/design-mcp}"
target_url="${NORSK_TARGET_URL:-${studio_url}/}"
request_method="${NORSK_REQUEST_METHOD:-GET}"
username="${NORSK_USERNAME:-}"
password="${NORSK_PASSWORD:-}"

if [[ -z "$username" || -z "$password" ]]; then
  echo "Missing NORSK_USERNAME or NORSK_PASSWORD." >&2
  usage >&2
  exit 1
fi

cookie_jar="$(mktemp)"
login_resp="$(mktemp)"

cleanup() {
  rm -f "$cookie_jar" "$login_resp"
}
trap cleanup EXIT

payload="$(
  NORSK_USERNAME="$username" \
  NORSK_PASSWORD="$password" \
  NORSK_TARGET_URL="$target_url" \
  NORSK_REQUEST_METHOD="$request_method" \
  node <<'NODE'
const payload = {
  username: process.env.NORSK_USERNAME || "",
  password: process.env.NORSK_PASSWORD || "",
  keepMeLoggedIn: true,
  targetURL: process.env.NORSK_TARGET_URL || "",
  requestMethod: process.env.NORSK_REQUEST_METHOD || "GET"
};
process.stdout.write(JSON.stringify(payload));
NODE
)"

curl -sS \
  -c "$cookie_jar" \
  -b "$cookie_jar" \
  -H "Content-Type: application/json" \
  -d "$payload" \
  "$auth_url/api/firstfactor" > "$login_resp"

status="$(
  node -e 'const fs=require("fs");const data=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));console.log(data.status||"");' \
    "$login_resp"
)"

if [[ "$status" != "OK" ]]; then
  echo "Login failed:" >&2
  cat "$login_resp" >&2
  exit 1
fi

cookie_header="$(
  node - <<'NODE' "$cookie_jar"
const fs = require("fs");
const jarPath = process.argv[1];
const lines = fs.readFileSync(jarPath, "utf8").split("\n");
const line = lines.find((l) => l && l.includes("\tauthelia_session\t"));
if (!line) process.exit(2);
const normalized = line.startsWith("#HttpOnly_") ? line.replace("#HttpOnly_", "") : line;
const parts = normalized.split("\t");
const name = parts[5];
const value = parts[6];
if (!name || !value) process.exit(2);
console.log(`${name}=${value}`);
NODE
)"

if [[ -z "$cookie_header" ]]; then
  echo "Auth cookie not found after login." >&2
  exit 1
fi

NORSK_COOKIE_HEADER="$cookie_header" \
NORSK_WS_URL="$ws_url" \
NORSK_STAY_OPEN="$stay_open" \
NORSK_CONNECT_TIMEOUT_MS="${NORSK_CONNECT_TIMEOUT_MS:-5000}" \
node <<'NODE'
const wsUrl = process.env.NORSK_WS_URL;
const cookieHeader = process.env.NORSK_COOKIE_HEADER;
const stayOpen = process.env.NORSK_STAY_OPEN === "true";
const timeoutMs = Number(process.env.NORSK_CONNECT_TIMEOUT_MS || 5000);

if (!wsUrl || !cookieHeader) {
  console.error("Missing WebSocket URL or auth cookie.");
  process.exit(1);
}

let opened = false;
const ws = new WebSocket(wsUrl, { headers: { Cookie: cookieHeader } });

ws.onopen = () => {
  opened = true;
  console.log("connected");
  if (!stayOpen) {
    setTimeout(() => ws.close(), 1000);
  }
};

ws.onmessage = (evt) => {
  if (typeof evt.data === "string") {
    console.log("message", evt.data.slice(0, 500));
  } else {
    console.log("message", "[binary]");
  }
};

ws.onerror = (err) => {
  console.error("error", err && err.message ? err.message : String(err));
};

ws.onclose = (evt) => {
  console.log("closed", evt.code, evt.reason || "");
  process.exit(opened ? 0 : 2);
};

setTimeout(() => {
  console.error("timeout");
  ws.close();
}, timeoutMs);
NODE
