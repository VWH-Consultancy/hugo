# Hugo development container for Podman/Docker using Alpine Linux
# Build: podman build -t hugo-dev .
# Run: podman run -p 1313:1313 -v $(pwd):/site hugo-dev

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04 AS builder

# Install dependencies
RUN apk add --no-cache \
    git \
    wget \
    ca-certificates

# Install Hugo extended (static binary)
ARG HUGO_VERSION=0.154.5
RUN wget -O /tmp/hugo.tar.gz \
    "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz" && \
    tar -xzf /tmp/hugo.tar.gz -C /tmp && \
    mv /tmp/hugo /usr/local/bin/hugo && \
    rm -rf /tmp/hugo.tar.gz /tmp/LICENSE /tmp/README.md

WORKDIR /site

# Copy the entire project (excluding files in .dockerignore)
COPY . .

# Initialize Git submodules (theme)
RUN git submodule update --init --recursive

# Expose the default Hugo server port
EXPOSE 1313

# Default command: run Hugo server with local baseURL
CMD ["hugo", "server", "--baseURL", "http://localhost:1313", "--bind", "0.0.0.0"]