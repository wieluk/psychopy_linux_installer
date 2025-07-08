#!/bin/bash
set -e

# Configuration
declare -A DISTROS=(
    ["1"]="ubuntu:24.04"
    ["2"]="fedora:latest"
    ["3"]="archlinux:latest"
    ["4"]="opensuse/leap:latest"
)

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Choose a distribution to test PsychoPy installer:${NC}"
echo "1) Ubuntu 24.04"
echo "2) Fedora Latest"
echo "3) Arch Linux"
echo "4) openSUSE Leap"
echo -n "Enter choice [1-4]: "

read -r choice

if [[ ! "${DISTROS[$choice]}" ]]; then
    echo "Invalid choice"
    exit 1
fi

distro="${DISTROS[$choice]}"
clean_name=$(echo "$distro" | sed 's/[^a-zA-Z0-9]/_/g')
container_name="psychopy_test_${clean_name}_${TIMESTAMP}"

echo -e "${BLUE}Starting interactive container for $distro...${NC}"

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Docker not found. You need to enable Docker-in-Docker or use host Docker.${NC}"
    echo -e "${YELLOW}To enable host Docker access, add to your devcontainer.json:${NC}"
    echo '  "mounts": ["source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"]'
    exit 1
fi

# Check if installer exists
if [ ! -f "/workspaces/psychopy_linux_installer/psychopy_linux_installer" ]; then
    echo -e "${RED}psychopy_linux_installer not found!${NC}"
    exit 1
fi

# Start container in background
echo -e "${BLUE}Starting container in background...${NC}"
docker run -d --name "$container_name" "$distro" sleep infinity

# Copy installer to container
echo -e "${BLUE}Copying installer to container...${NC}"
docker cp "/workspaces/psychopy_linux_installer/psychopy_linux_installer" "$container_name:/psychopy_linux_installer"

# Make it executable
docker exec "$container_name" chmod +x /psychopy_linux_installer

# Start interactive session
echo -e "${GREEN}Starting interactive session...${NC}"
docker exec -it "$container_name" bash -c "
    echo 'Distribution: $distro'
    echo 'Container: $container_name'
    echo 'Installer copied to: /psychopy_linux_installer'
    echo ''
    echo '============================================='
    echo 'Running the installer automatically...'
    echo '============================================='
    echo ''
    /psychopy_linux_installer
    echo ''
    bash
"

# Cleanup
echo -e "${BLUE}Cleaning up container...${NC}"
docker stop "$container_name" >/dev/null 2>&1
docker rm "$container_name" >/dev/null 2>&1

echo -e "${GREEN}Session complete.${NC}"