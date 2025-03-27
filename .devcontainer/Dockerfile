FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    python3-pip \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install bashate codespell --break-system-packages

# Copy the installer script
COPY psychopy_linux_installer /tmp/

# Make the installer executable and run it
RUN chmod +x /tmp/psychopy_linux_installer && \
    /tmp/psychopy_linux_installer --install-dir=/psychopy --venv-name=psychopy-test-installation -f --non-interactive --additional-packages=pytest
