# Norsk MCP quick connect

Use `connect_norsk_mcp.sh` to authenticate to Norsk Studio and open the
design-time MCP WebSocket. This lets a new session reconnect quickly without
redoing the manual steps.

## Quick start
Set credentials in the shell for the current session, then run:

NORSK_USERNAME="your-username" NORSK_PASSWORD="your-password" ./connect_norsk_mcp.sh

To keep the WebSocket open, add:

./connect_norsk_mcp.sh --stay-open

## Optional environment variables
- NORSK_AUTH_URL (default: https://auth.liveencode.com)
- NORSK_STUDIO_URL (default: https://studio.liveencode.com)
- NORSK_MCP_WS_URL (default: wss://studio.liveencode.com/design-mcp)
- NORSK_TARGET_URL (default: ${NORSK_STUDIO_URL}/)
- NORSK_REQUEST_METHOD (default: GET)
- NORSK_CONNECT_TIMEOUT_MS (default: 5000)

## Safe credential handling
- Avoid committing credentials to the repo.
- You can store exports in a local shell file (outside the repo), then source it:
  source ~/.norsk_mcp.env
