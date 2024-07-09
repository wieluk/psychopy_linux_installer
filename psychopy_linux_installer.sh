#!/bin/bash

# Exit on any error
set -e

# Help function
show_help() {
    echo "Usage: ./install_psychopy.sh [options]"
    echo "Options:"
    echo "  --python_version=VERSION    Specify the Python version to install (default: 3.8.16)"
    echo "  --psychopy_version=VERSION  Specify the PsychoPy version to install (default: latest); use git for latest github version"
    echo "  --install_dir=DIR           Specify the installation directory (default: ~/)"
    echo "  -f, --force                 Force overwrite of existing installation directory"
    echo "  -h, --help                  Show this help message"
}

# Default versions and directory
PYTHON_VERSION="3.8.16"
PSYCHOPY_VERSION="latest"
INSTALL_DIR=${HOME}
FORCE_OVERWRITE=false

# Parse input arguments
for i in "$@"; do
    case $i in
        --python_version=*)
            PYTHON_VERSION="${i#*=}"
            shift
            ;;
        --psychopy_version=*)
            PSYCHOPY_VERSION="${i#*=}"
            shift
            ;;
        --install_dir=*)
            INSTALL_DIR="${i#*=}"
            shift
            ;;
        -f|--force)
            FORCE_OVERWRITE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $i"
            show_help
            exit 1
            ;;
    esac
done

# Function to detect the package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "none"
    fi
}

# Function to install packages using the detected package manager
install_packages() {
    local pkg_manager=$1
    shift
    local packages=("$@")

    case $pkg_manager in
        apt)
            sudo apt-get update
            for package in "${packages[@]}"; do
                sudo apt-get install -y "$package" || echo "Package $package not found, skipping."
            done
            ;;
        yum)
            sudo yum update -y
            for package in "${packages[@]}"; do
                sudo yum install -y "$package" || echo "Package $package not found, skipping."
            done
            ;;
        dnf)
            sudo dnf update -y
            for package in "${packages[@]}"; do
                sudo dnf install -y "$package" || echo "Package $package not found, skipping."
            done
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            for package in "${packages[@]}"; do
                sudo pacman -S --noconfirm "$package" || echo "Package $package not found, skipping."
            done
            ;;
        *)
            echo "No compatible package manager found."
            exit 1
            ;;
    esac
}


# Function to check if the given Python version exists for download
check_python_version() {
    local version=$1
    if curl --output /dev/null --silent --head --fail "https://www.python.org/ftp/python/${version}/Python-${version}.tgz"; then
        echo "Python version ${version} exists for download."
    else
        echo "Python version ${version} does not exist. Exiting."
        exit 1
    fi
}

# Function to get the latest PsychoPy version
get_latest_psychopy_version() {
    local latest_version=$(curl -s https://pypi.org/pypi/psychopy/json | jq -r .info.version)
    echo $latest_version
}

# Function to check if the given PsychoPy version exists
check_psychopy_version() {
    local version=$1
    if curl -s https://pypi.org/pypi/psychopy/${version}/json | jq -e .info.version > /dev/null; then
        echo "PsychoPy version ${version} exists."
    else
        echo "PsychoPy version ${version} does not exist. Exiting."
        exit 1
    fi
}

# Welcome message
echo "Starting the installation of PsychoPy with Python $PYTHON_VERSION"

# Detect the package manager
pkg_manager=$(detect_package_manager)
if [ "$pkg_manager" == "none" ]; then
    echo "No compatible package manager found. Exiting."
    exit 1
fi


# List of dependencies
dependencies=()
case $pkg_manager in
    apt)
        dependencies=(
            git build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl libbz2-dev libsqlite3-dev libusb-1.0-0-dev portaudio19-dev libasound2-dev libgtk-3-dev jq
            libxcb-cursor0 libxcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-render0 libxcb-shape0 libxcb-shm0 libxcb-util1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xinput0 libxcb-xkb1 libxkbcommon-x11-0
        )
        ;;
    yum|dnf)
        dependencies=(
            git gcc-c++ gcc zlib-devel ncurses-devel gdbm-devel nss-devel openssl-devel readline-devel libffi-devel curl bzip2-devel sqlite-devel libusb-devel portaudio-devel alsa-lib-devel gtk3-devel jq
            xcb-util-cursor-devel libxcb libxcb-devel libxcb-icccm4-devel libxcb-image-devel libxcb-keysyms-devel libxcb-render-util-devel libxcb-render-devel libxcb-shape-devel libxcb-shm-devel libxcb-util-devel 
            libxcb-xfixes-devel libxcb-xinerama-devel libxcb-xinput-devel libxcb-xkb-devel xkbcommon-x11-devel freeglut-devel
        )
        ;;
    pacman)
        dependencies=(
            git base-devel zlib ncurses gdbm nss openssl readline libffi curl bzip2 sqlite libusb portaudio alsa-lib gtk3 jq
            xcb-util-cursor libxcb libxcb-icccm libxcb-image libxcb-keysyms libxcb-render libxcb-render-util libxcb-shape libxcb-shm libxcb-util libxcb-xfixes libxcb-xinerama libxcb-xinput libxcb-xkb xkbcommon-x11
        )
        ;;
esac

# Install dependencies
install_packages "$pkg_manager" "${dependencies[@]}"

# Check if the provided Python version exists for download
check_python_version ${PYTHON_VERSION}

# Determine the PsychoPy version
if [ "$PSYCHOPY_VERSION" == "latest" ]; then
    PSYCHOPY_VERSION=$(get_latest_psychopy_version)
elif [ "$PSYCHOPY_VERSION" == "git" ]; then
    PSYCHOPY_VERSION="_git"
    echo "Using PsychoPy version from git."
else
    check_psychopy_version ${PSYCHOPY_VERSION}
fi

# Clean version strings
PSYCHOPY_VERSION_CLEAN=$(echo ${PSYCHOPY_VERSION} | tr -d ',;')
PYTHON_VERSION_CLEAN=$(echo ${PYTHON_VERSION} | tr -d ',;')

# Create PsychoPy directory
PSYCHOPY_DIR=${INSTALL_DIR}/psychopy_v${PSYCHOPY_VERSION_CLEAN}_py_v${PYTHON_VERSION_CLEAN}
if [ -d "${PSYCHOPY_DIR}" ]; then
    if [ "$FORCE_OVERWRITE" = true ]; then
        echo "Directory ${PSYCHOPY_DIR} already exists. Overwriting..."
        rm -rf "${PSYCHOPY_DIR}"
    else
        echo "Directory ${PSYCHOPY_DIR} already exists. Exiting."
        exit 1
    fi
fi
echo "Creating PsychoPy directory at ${PSYCHOPY_DIR}..."
mkdir -p ${PSYCHOPY_DIR}
cd ${PSYCHOPY_DIR}

# Check if the specified Python version is already installed
if python${PYTHON_VERSION%.*} --version 2>&1 | grep -q ${PYTHON_VERSION}; then
    echo "Python version ${PYTHON_VERSION} is already installed."
else
    echo "Downloading and installing Python ${PYTHON_VERSION}..."
    curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    tar -xf Python-${PYTHON_VERSION}.tgz
    cd Python-${PYTHON_VERSION}
    ./configure --enable-optimizations
    make -j $(nproc)
    sudo make altinstall
    cd ..
    sudo rm -rf Python-${PYTHON_VERSION}*
fi

# Create and activate virtual environment
echo "Creating virtual environment..."
python${PYTHON_VERSION%.*} -m venv ${PSYCHOPY_DIR}/psychopy_venv
echo "Activating virtual environment..."
source ${PSYCHOPY_DIR}/psychopy_venv/bin/activate

# Upgrade pip and setuptools, and install wxPython
echo "Upgrading pip and setuptools..."
pip install --upgrade pip setuptools distro
echo "Installing wxPython..."
pip install wxPython

# Install PsychoPy
if [ "$PSYCHOPY_VERSION" == "_git" ]; then
    pip install git+https://github.com/psychopy/psychopy
else
    pip install psychopy==${PSYCHOPY_VERSION}
fi

deactivate

sudo groupadd --force psychopy
sudo usermod -a -G psychopy $USER

echo -e "@psychopy - nice -20\n@psychopy - rtprio 50\n@psychopy - memlock unlimited" | sudo tee -a /etc/security/limits.d/99-psychopylimits.conf

mkdir -p ${PSYCHOPY_DIR}/.bin
ln -sf "${PSYCHOPY_DIR}/psychopy_venv/bin/psychopy" ${PSYCHOPY_DIR}/.bin/psychopy_v${PSYCHOPY_VERSION_CLEAN}_py_v${PYTHON_VERSION_CLEAN}
echo 'export PATH="${PSYCHOPY_DIR}/.bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo
echo "PsychoPy installation complete!"
echo "To apply the changes, run:"
echo "source ~/.bashrc"
echo
echo "To start PsychoPy, use:"
echo "psychopy_v${PSYCHOPY_VERSION_CLEAN}_py_v${PYTHON_VERSION_CLEAN}"
