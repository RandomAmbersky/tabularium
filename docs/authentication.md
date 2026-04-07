# Authentication and authorization

Tabularium itself does **not** implement built-in authentication or authorization.

That applies to the server surfaces it exposes directly:

- web UI
- REST API
- JSON-RPC
- document WebSocket
- MCP endpoint

If you expose Tabularium beyond `localhost`, put it behind an external control plane such as:

- a reverse proxy
- a web front-end server
- an API gateway
- a WAF
- a VPN / private network boundary

Typical deployment pattern:

1. The front-end proxy verifies the caller.
2. The proxy allows or denies the request.
3. The proxy optionally forwards credentials or identity headers upstream.
4. Tabularium serves the request after the proxy has already made the access decision.

## What Tabularium can and cannot do

Tabularium can:

- listen on HTTP and let an external component protect it
- accept ordinary HTTP headers from clients and proxies
- let `tb` send extra headers on every JSON-RPC and WebSocket request

Tabularium cannot:

- manage users, passwords, sessions, roles, or ACLs
- validate bearer tokens on its own
- enforce per-document permissions on its own

## Keep it private

The simplest model is to bind Tabularium to `127.0.0.1` or a private network and only expose it through another service that already handles authentication.

## HTTP Basic authentication at the proxy

Your proxy can require HTTP Basic auth before forwarding to Tabularium.

Example with `curl`:

```bash
export BASE=https://tabularium.example.com

curl -sS -u 'alice:correct-horse-battery-staple' \
  "$BASE/api/search?q=meeting"
```

Example with `tb` using `TB_HEADERS`:

```bash
export BASIC_AUTH="$(printf '%s' 'alice:correct-horse-battery-staple' | base64)"
export TB_HEADERS="$(cat <<EOF
Authorization: Basic $BASIC_AUTH
EOF
)"

tb -u https://tabularium.example.com ls /
tb -u https://tabularium.example.com search meeting
```

Ad-hoc example with `--header`:

```bash
tb -u https://tabularium.example.com \
  --header "Authorization: Basic $BASIC_AUTH" \
  ls /
```

`--header` is convenient for one-off calls, but the value is visible in shell history and `ps`. For secrets, `TB_HEADERS` is the less embarrassing ritual.

## Bearer token at the proxy or gateway

Your proxy or gateway can require `Authorization: Bearer ...` before forwarding to Tabularium.

Example with `curl`:

```bash
export BASE=https://tabularium.example.com

curl -sS \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  "$BASE/api/search?q=meeting"
```

Example with `tb`:

```bash
export TB_HEADERS="$(cat <<'EOF'
Authorization: Bearer YOUR_TOKEN
EOF
)"

tb -u https://tabularium.example.com test
tb -u https://tabularium.example.com ls /
```

One-off invocation:

```bash
tb -u https://tabularium.example.com \
  --header 'Authorization: Bearer YOUR_TOKEN' \
  cat /notes/readme
```

## Custom auth or identity headers

Some front-end systems do not use `Authorization` directly. They may expect or inject headers such as:

- `X-Forwarded-User`
- `X-Auth-Request-User`
- `X-Remote-User`
- `X-Org`
- `X-Role`

In that model, the external front-end still performs authentication and authorization. The headers are just the contract between the client and that front-end, or between the front-end and Tabularium. Tabularium itself does not interpret `X-Forwarded-User`, `X-Role`, and similar headers as permission rules.

Example with `curl`:

```bash
curl -sS \
  -H 'X-Forwarded-User: alice@example.com' \
  -H 'X-Org: docs' \
  'https://tabularium.example.com/api/doc'
```

Example with `tb`:

```bash
export TB_HEADERS="$(cat <<'EOF'
X-Forwarded-User: alice@example.com
X-Org: docs
EOF
)"

tb -u https://tabularium.example.com ls /
tb -u https://tabularium.example.com chat /meetings/weekly.md -i Logis
```

## `tb` header handling

`tb` supports extra HTTP headers on every JSON-RPC request and every WebSocket upgrade.

- Use repeated `--header 'Name: value'` for ad-hoc calls.
- Use `TB_HEADERS` for secrets or shared session setup.
- `TB_HEADERS` uses one `Name: value` per line.
- Empty lines and lines starting with `#` are ignored.
- If the same header name appears more than once, later values win.
- Precedence is `TB_HEADERS`, then repeated `--header` flags.

Example with multiple headers:

```bash
export TB_HEADERS="$(cat <<'EOF'
# accepted by the front-end proxy
Authorization: Bearer YOUR_TOKEN
X-Org: docs
EOF
)"

tb -u https://tabularium.example.com search roadmap
tb -u https://tabularium.example.com chat /rooms/ops.md -i Logis
```

The same header set is used for WebSocket-based commands too, so proxy-protected chat flows work without a separate configuration knob. Mercifully, one less shrine to maintain.

## Recommendation

For anything outside local development:

- do not expose a raw unauthenticated Tabularium server to the public internet
- terminate TLS at your proxy or gateway
- enforce authentication and authorization there
- pass only the headers Tabularium or your surrounding infrastructure actually needs
- prefer `TB_HEADERS` over `--header` when credentials are sensitive
