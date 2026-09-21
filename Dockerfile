FROM python:3.11-slim@sha256:da047cb8f9d1d98e5c070f5300ba9f7274e33b8fc0e5be5ed88740aed1b95ba9 AS base
LABEL maintainer="Soxoj <soxoj@protonmail.com>"
WORKDIR /app
RUN pip install --no-cache-dir --upgrade pip
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      build-essential \
      python3-dev \
      pkg-config \
      libcairo2-dev \
      libxml2-dev \
      libxslt1-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/*
COPY . .
RUN YARL_NO_EXTENSIONS=1 python3 -m pip install --no-cache-dir .
# Run as an unprivileged user; HOME=/home/maigret gives ~/.maigret for DB auto-update
RUN useradd --create-home --uid 10001 maigret \
    && mkdir -p /app/reports \
    && chown -R maigret:maigret /app
USER maigret

# Web UI variant: auto-launches the web interface on $PORT
FROM base AS web
# 0.0.0.0 is required for `-p` port publishing; the web UI refuses to bind a
# non-loopback address unless MAIGRET_WEB_TOKEN (or MAIGRET_WEB_INSECURE=1) is set
ENV FLASK_HOST=0.0.0.0
ENV PORT=5000
EXPOSE 5000
ENTRYPOINT ["sh", "-c", "exec maigret --web \"$PORT\""]

# Default variant (last stage = `docker build .` target): CLI, backwards-compatible
FROM base AS cli
ENTRYPOINT ["maigret"]
