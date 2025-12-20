# WRX deploy: decrypting / installing SSH keys (test sessions)

This repo does **not** store private keys. In a fresh environment you must supply a deploy key (plain or encrypted), then install it into `~/.ssh` with correct permissions.

## Option A: provide a plain private key (base64)

1. Base64 the private key **on your machine**:

```bash
base64 -w0 id_ed25519
```

2. In your session, set environment variables and run:

```bash
export WRX_SSH_HOST="wrx.liveencode.com"
export WRX_SSH_USER="ubuntu"          # change if needed
export WRX_SSH_PRIVATE_KEY_B64="..."  # paste base64 output

bash scripts/wrx_ssh_setup.sh
```

## Option B: provide an encrypted private key (OpenSSL AES-256-CBC + PBKDF2)

1. Encrypt **on your machine**:

```bash
openssl enc -aes-256-cbc -pbkdf2 -salt -in id_ed25519 -out id_wrx.enc
base64 -w0 id_wrx.enc
```

2. In your session:

```bash
export WRX_SSH_HOST="wrx.liveencode.com"
export WRX_SSH_USER="ubuntu"                    # change if needed
export WRX_SSH_PRIVATE_KEY_ENC_B64="..."        # paste base64 output
export WRX_SSH_PRIVATE_KEY_PASSPHRASE="..."     # encryption passphrase

bash scripts/wrx_ssh_setup.sh
```

## Option C: provide an encrypted key file path (OpenSSL)

If you already have `id_wrx.enc` present in the filesystem:

```bash
export WRX_SSH_HOST="wrx.liveencode.com"
export WRX_SSH_USER="ubuntu"
export WRX_SSH_PRIVATE_KEY_PASSPHRASE="..."

bash scripts/wrx_ssh_setup.sh /path/to/id_wrx.enc
```

## Quick connectivity test

After setup, you should have a `Host wrx` stanza in `~/.ssh/config`, so:

```bash
ssh -o BatchMode=yes wrx 'echo connected'
```

If the host key is unknown, SSH will prompt you interactively the first time. You can also pre-seed it with:

```bash
ssh-keyscan -H "$WRX_SSH_HOST" >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
```

