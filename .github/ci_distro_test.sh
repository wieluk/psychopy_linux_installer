#!/bin/bash
set -e

DISTRO="$1"
INSTALLER_ARGS="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/ci_distro_test_logs"
RESULT_FILE="${LOG_DIR}/result.txt"
CONTAINER_NAME="psychopy_test"

mkdir -p "$LOG_DIR"

echo "Testing: $DISTRO"
echo "Args: $INSTALLER_ARGS"

# Start container
docker run -d --name "$CONTAINER_NAME" "$DISTRO" sleep infinity || { echo "FAILED_CONTAINER_START" > "$RESULT_FILE"; exit 1; }

# Copy files
docker cp "$SCRIPT_DIR/../psychopy_linux_installer" "$CONTAINER_NAME:/psychopy_linux_installer"
docker exec "$CONTAINER_NAME" chmod +x /psychopy_linux_installer
docker cp "$SCRIPT_DIR/psychopy_tests/test_program" "$CONTAINER_NAME:/test_program"

# Pre-fix distro-specific issues
if [[ "$DISTRO" == *"rockylinux"* ]]; then
    docker exec "$CONTAINER_NAME" bash -c "dnf install -y curl sudo --allowerasing"
elif [[ "$DISTRO" == *"opensuse"* ]]; then
    docker exec "$CONTAINER_NAME" bash -c "zypper install -y sudo"
elif [[ "$DISTRO" == *"debian"* ]]; then
    docker exec "$CONTAINER_NAME" bash -c "apt-get update && apt-get install -y sudo"
fi

# Install xvfb
if [[ "$DISTRO" == *"ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
    docker exec "$CONTAINER_NAME" bash -c "apt-get update && apt-get install -y xvfb"
elif [[ "$DISTRO" == *"fedora"* ]] || [[ "$DISTRO" == *"rockylinux"* ]]; then
    docker exec "$CONTAINER_NAME" bash -c "dnf install -y xorg-x11-server-Xvfb"
fi

# Run installer
echo "Running installer..."
if ! docker exec "$CONTAINER_NAME" bash -c "/psychopy_linux_installer --install-dir=/tmp_dir --venv-name=psychopy --additional-packages=pytest,psychopy-bids -f --non-interactive $INSTALLER_ARGS"; then
    echo "FAILED_INSTALL" > "$RESULT_FILE"
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1
    exit 1
fi

echo "PASSED" > "$RESULT_FILE"
echo "Installation completed successfully"