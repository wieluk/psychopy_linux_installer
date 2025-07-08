#!/bin/bash
set -e

# Configuration
declare -A DISTROS=(
    ["1"]="ubuntu:24.04"
    ["2"]="fedora:latest"
    ["3"]="archlinux:latest"
    ["4"]="opensuse/leap:latest"
)

declare -A DISTRO_ARGS=(
    ["ubuntu:24.04"]="-f --non-interactive"
    ["fedora:latest"]="-f --non-interactive"
    ["archlinux:latest"]="-f --non-interactive --wxpython-wheel-index=https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-24.04/"
    ["opensuse/leap:latest"]="-f --non-interactive"
)

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="$(dirname "$0")/$(basename "$0" .sh)_logs"
INSTALLER_PATH="$(git rev-parse --show-toplevel)/psychopy_linux_installer"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to run installer on a single distro
run_single_distro() {
    local distro="$1"
    local interactive="$2"
    
    local clean_name
    clean_name=$(echo "$distro" | sed 's/[^a-zA-Z0-9]/_/g')
    local container_name="psychopy_test_${clean_name}_${TIMESTAMP}"
    
    echo -e "${BLUE}Starting container for $distro...${NC}"

    sudo docker run -d --name "$container_name" "$distro" sleep infinity
    sudo docker cp "$INSTALLER_PATH" "$container_name:/psychopy_linux_installer"
    sudo docker exec "$container_name" chmod +x /psychopy_linux_installer
    
    if [ "$interactive" = "true" ]; then
        echo -e "${GREEN}Starting interactive session...${NC}"
        echo ""
        "$INSTALLER_PATH" --help
        echo ""
        echo -e "${YELLOW}Enter installer arguments (e.g., --non-interactive -f) or leave empty and press enter for none:${NC}"
        read -r installer_args
        
        sudo docker exec -it "$container_name" bash -c "
            echo 'Distribution: $distro'
            echo 'Container: $container_name'
            echo 'Installer copied to: /psychopy_linux_installer'
            echo 'Arguments: $installer_args'
            echo ''
            echo '============================================='
            echo 'Running the installer with arguments: $installer_args'
            echo '============================================='
            echo ''
            /psychopy_linux_installer $installer_args
            echo ''
            bash
        "
    else
        # Non-interactive mode with logging
        local distro_log_dir="${LOG_DIR}/${clean_name}"
        mkdir -p "$distro_log_dir"
        local log_file="${distro_log_dir}/psychopy_test_${clean_name}_${TIMESTAMP}.log"
        echo -e "${BLUE}Running installer on $distro (non-interactive, logging to $log_file)...${NC}"
        
        local installer_args="${DISTRO_ARGS[$distro]}"
        
        sudo docker exec "$container_name" bash -c "
            echo 'Distribution: $distro'
            echo 'Container: $container_name'
            echo 'Installer copied to: /psychopy_linux_installer'
            echo 'Timestamp: $(date)'
            echo ''
            echo '============================================='
            echo 'Running the installer with $installer_args flags...'
            echo '============================================='
            echo ''
            /psychopy_linux_installer $installer_args
            echo ''
            echo 'Installation completed at: $(date)'
        " 2>&1 | sudo tee "$log_file" > /dev/null
        
        echo -e "${GREEN}Completed $distro - log saved to $log_file${NC}"
    fi
    
    sudo docker stop "$container_name" >/dev/null 2>&1
    sudo docker rm "$container_name" >/dev/null 2>&1
}

# Function to run on all distros in parallel
run_all_distros() {
    mkdir -p "$LOG_DIR"
    
    echo -e "${GREEN}Running PsychoPy installer on all distributions in parallel...${NC}"
    echo -e "${BLUE}Logs will be saved to: $LOG_DIR${NC}"
    echo ""
    
    local pids=()
    for key in "${!DISTROS[@]}"; do
        local distro="${DISTROS[$key]}"
        echo -e "${YELLOW}Starting $distro in background...${NC}"
        run_single_distro "$distro" "false" &
        pids+=($!)
    done
    
    echo -e "${BLUE}All containers started in parallel. Waiting for completion...${NC}"
    echo ""
    
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    echo -e "${GREEN}All distributions completed!${NC}"
    echo -e "${BLUE}Check logs in: $LOG_DIR${NC}"
}

echo -e "${GREEN}Choose a distribution to test PsychoPy installer:${NC}"
echo "1) Ubuntu 24.04"
echo "2) Fedora Latest"
echo "3) Arch Linux"
echo "4) openSUSE Leap"
echo "5) Run on ALL distros (non-interactive, with logging)"
echo -n "Enter choice [1-5]: "

read -r choice

if [[ ! "${DISTROS[$choice]}" && "$choice" != "5" ]]; then
    echo "Invalid choice"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Docker not found. You need to enable Docker-in-Docker or use host Docker.${NC}"
    echo -e "${YELLOW}To enable host Docker access, add to your devcontainer.json:${NC}"
    echo '  "mounts": ["source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"]'
    exit 1
fi

if [ ! -f "$INSTALLER_PATH" ]; then
    echo -e "${RED}psychopy_linux_installer not found!${NC}"
    exit 1
fi

if [ "$choice" = "5" ]; then
    run_all_distros
else
    distro="${DISTROS[$choice]}"
    echo -e "${BLUE}Starting interactive container for $distro...${NC}"
    run_single_distro "$distro" "true"
fi

echo -e "${GREEN}Session complete.${NC}"