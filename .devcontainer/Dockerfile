FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    python3-pip \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install bashate codespell --break-system-packages
