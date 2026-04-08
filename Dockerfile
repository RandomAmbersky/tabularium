FROM node:22-bookworm-slim AS ui-builder

WORKDIR /work/ui
COPY ui/package.json ui/package-lock.json ./
RUN npm ci
COPY ui/ .
RUN npm run build


FROM rust:1-bookworm AS builder

WORKDIR /work
COPY . .

# Provide `ui/dist` for include_dir! embedding.
COPY --from=ui-builder /work/ui/dist ./ui/dist

# Build server with MCP enabled, plus `tb`.
RUN cargo build --release --features mcp -p tabularium-server -p tabularium-cli


FROM debian:bookworm-slim AS runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libssl3 \
    libsqlite3-0 \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -r -u 10001 -g nogroup -m -d /nonexistent -s /usr/sbin/nologin tabularium

RUN mkdir -p /etc/tabularium /var/tabularium/data /var/tabularium/spill \
  && chown -R tabularium:nogroup /var/tabularium

COPY --from=builder /work/target/release/tabularium-server /usr/sbin/tabularium-server
COPY --from=builder /work/target/release/tb /usr/bin/tb
COPY docker/config.toml /etc/tabularium/config.toml

EXPOSE 3050
EXPOSE 3031

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=6 \
  CMD curl -fsS http://127.0.0.1:3050/api/test >/dev/null || exit 1

USER tabularium

ENTRYPOINT ["/usr/sbin/tabularium-server"]
CMD ["--config", "/etc/tabularium/config.toml"]

