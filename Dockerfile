# Hugo development container for Docker using Ubuntu
# Build: docker build -t hugo .
# Run: docker run -p 1313:1313 -v $(pwd):/site hugo

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Hugo extended (static binary) - detect architecture
ARG HUGO_VERSION=0.154.5
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) HUGO_ARCH="64bit" ;; \
        aarch64|arm64) HUGO_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;; \
    esac && \
    wget -O /tmp/hugo.tar.gz \
    "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-${HUGO_ARCH}.tar.gz" && \
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
