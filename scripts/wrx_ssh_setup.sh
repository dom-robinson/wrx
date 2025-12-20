#!/usr/bin/env bash
set -euo pipefail

# Safe SSH key setup for WRX deploy sessions.
#
# Supports:
#   1) Plain private key (base64) via WRX_SSH_PRIVATE_KEY_B64
#   2) OpenSSL-encrypted blob (base64) via WRX_SSH_PRIVATE_KEY_ENC_B64 + WRX_SSH_PRIVATE_KEY_PASSPHRASE
#   3) A local encrypted file path (arg1) + passphrase (WRX_SSH_PRIVATE_KEY_PASSPHRASE)
#
# Writes:
#   ~/.ssh/id_wrx (mode 600)
#   ~/.ssh/config snippet for Host "wrx"
#
# Required for config:
#   WRX_SSH_HOST (e.g. wrx.liveencode.com)
# Optional:
#   WRX_SSH_USER (default: ubuntu)

die() { echo "error: $*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

need base64
need openssl

WRX_SSH_HOST="${WRX_SSH_HOST:-}"
WRX_SSH_USER="${WRX_SSH_USER:-ubuntu}"

[[ -n "$WRX_SSH_HOST" ]] || die "WRX_SSH_HOST is required"

umask 077
mkdir -p "$HOME/.ssh"

KEY_PATH="$HOME/.ssh/id_wrx"
CONFIG_PATH="$HOME/.ssh/config"

write_plain_key_from_b64() {
  [[ -n "${WRX_SSH_PRIVATE_KEY_B64:-}" ]] || die "WRX_SSH_PRIVATE_KEY_B64 is empty"
  base64 -d <<<"$WRX_SSH_PRIVATE_KEY_B64" >"$KEY_PATH"
}

decrypt_openssl_from_b64() {
  [[ -n "${WRX_SSH_PRIVATE_KEY_ENC_B64:-}" ]] || die "WRX_SSH_PRIVATE_KEY_ENC_B64 is empty"
  [[ -n "${WRX_SSH_PRIVATE_KEY_PASSPHRASE:-}" ]] || die "WRX_SSH_PRIVATE_KEY_PASSPHRASE is required to decrypt"

  # Expecting output created with something like:
  #   openssl enc -aes-256-cbc -pbkdf2 -salt -in id_wrx -out id_wrx.enc
  #   base64 -w0 id_wrx.enc
  base64 -d <<<"$WRX_SSH_PRIVATE_KEY_ENC_B64" \
    | openssl enc -d -aes-256-cbc -pbkdf2 -salt -pass "env:WRX_SSH_PRIVATE_KEY_PASSPHRASE" \
    >"$KEY_PATH"
}

decrypt_openssl_from_file() {
  local enc_path="$1"
  [[ -f "$enc_path" ]] || die "encrypted key file not found: $enc_path"
  [[ -n "${WRX_SSH_PRIVATE_KEY_PASSPHRASE:-}" ]] || die "WRX_SSH_PRIVATE_KEY_PASSPHRASE is required to decrypt"

  openssl enc -d -aes-256-cbc -pbkdf2 -salt \
    -in "$enc_path" \
    -pass "env:WRX_SSH_PRIVATE_KEY_PASSPHRASE" \
    >"$KEY_PATH"
}

ENC_FILE_PATH="${1:-}"
if [[ -n "$ENC_FILE_PATH" ]]; then
  decrypt_openssl_from_file "$ENC_FILE_PATH"
elif [[ -n "${WRX_SSH_PRIVATE_KEY_B64:-}" ]]; then
  write_plain_key_from_b64
elif [[ -n "${WRX_SSH_PRIVATE_KEY_ENC_B64:-}" ]]; then
  decrypt_openssl_from_b64
else
  die "provide either arg1=<encrypted key file> or WRX_SSH_PRIVATE_KEY_B64 or WRX_SSH_PRIVATE_KEY_ENC_B64"
fi

chmod 600 "$KEY_PATH"

# Basic sanity check that we didn't write garbage.
if command -v ssh-keygen >/dev/null 2>&1; then
  ssh-keygen -y -f "$KEY_PATH" >/dev/null 2>&1 || die "written key is not a valid SSH private key"
fi

# Append/update a simple Host entry for convenience.
{
  echo ""
  echo "Host wrx"
  echo "  HostName ${WRX_SSH_HOST}"
  echo "  User ${WRX_SSH_USER}"
  echo "  IdentityFile ${KEY_PATH}"
  echo "  IdentitiesOnly yes"
} >>"$CONFIG_PATH"

chmod 600 "$CONFIG_PATH" || true

echo "OK: wrote ${KEY_PATH} and added Host 'wrx' to ${CONFIG_PATH}"
