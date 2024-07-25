#!/bin/bash
set -e
trap 'catch_errors $LINENO $BASH_COMMAND' ERR

catch_errors() {
    local lineno=$1
    local cmd=$2
    echo "Error on line $lineno: $cmd"
    exit 1
}

# Help function
show_help() {
    echo "Usage: ./install_psychopy.sh [options]"
    echo "Options:"
    echo "  --python_version=VERSION    Specify the Python version to install (default: 3.8.16)"
    echo "  --psychopy_version=VERSION  Specify the PsychoPy version to install (default: 2024.1.4); use latest for latest pypi version; use git for latest github version"
    echo "  --install_dir=DIR           Specify the installation directory (default: \"$HOME\")"
    echo "  --bids_version=VERSION      Specify the PsychoPy-BIDS version to install; skip if not set"
    echo "  -f, --force                 Force overwrite of existing installation directory"
    echo "  -v, --verbose               Enable verbose output"
    echo "  -h, --help                  Show this help message"
    echo "  --build=[python|wxpython|both] Build Python and/or wxPython from source instead of downloading"
}

# Default versions and directory
PYTHON_VERSION="3.8.16"
PSYCHOPY_VERSION="2024.1.4"
INSTALL_DIR="$HOME"
BIDS_VERSION=""
FORCE_OVERWRITE=false
VERBOSE=false
BUILD_PYTHON=false
BUILD_WX=false

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
        --bids_version=*)
            BIDS_VERSION="${i#*=}"
            shift
            ;;
        -f|--force)
            FORCE_OVERWRITE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --build=*)
            BUILD_ARG="${i#*=}"
            if [[ "$BUILD_ARG" == "python" ]]; then
                BUILD_PYTHON=true
            elif [[ "$BUILD_ARG" == "wxpython" ]]; then
                BUILD_WX=true
            elif [[ "$BUILD_ARG" == "both" ]]; then
                BUILD_PYTHON=true
                BUILD_WX=true
            else
                echo "Invalid option for --build: $BUILD_ARG"
                show_help
                exit 1
            fi
            shift
            ;;
        *)
            echo "Unknown option: $i"
            show_help
            exit 1
            ;;
    esac
done

# Logging function for verbose output
log() {
    if [ "$VERBOSE" = true ]; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

# Function to detect OS version
detect_os_version() {
    if [ -f /etc/os-release ]; then
        # Freedesktop.org and systemd
        . /etc/os-release
        echo "$ID-$VERSION_ID"
    elif type lsb_release >/dev/null 2>&1; then
        # Linux Standard Base (LSB) support
        echo "$(lsb_release -si)-$(lsb_release -sr)"
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        echo "$DISTRIB_ID-$DISTRIB_RELEASE"
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu releases
        echo "Debian-$(cat /etc/debian_version)"
    elif [ -f /etc/redhat-release ]; then
        cat /etc/redhat-release
    else
        echo "Unknown"
    fi
}

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
            log sudo apt-get update
            for package in "${packages[@]}"; do
                log sudo apt-get install -y "$package" || echo "Package $package not found, skipping."
            done
            ;;
        yum)
            log sudo yum update -y
            for package in "${packages[@]}"; do
                log sudo yum install -y "$package" || echo "Package $package not found, skipping."
            done
            ;;
        dnf)
            log sudo dnf update -y
            for package in "${packages[@]}"; do
                log sudo dnf install -y "$package" || echo "Package $package not found, skipping."
            done
            ;;
        pacman)
            log sudo pacman -Syu --noconfirm
            for package in "${packages[@]}"; do
                log sudo pacman -S --noconfirm "$package" || echo "Package $package not found, skipping."
            done
            ;;
        *)
            echo "No compatible package manager found."
            exit 1
            ;;
    esac
}

# Function to install dependencies
install_basic_dependencies() {
    local pkg_manager=$1
    local dep_type=$2
    local dependencies=()
    
    case $pkg_manager in
        apt)
            python_build_deps=(
                build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev
                libffi-dev libbz2-dev libsqlite3-dev
            )
            psychopy_basic_deps=(
                git curl libusb-1.0-0-dev portaudio19-dev libasound2-dev jq
                libxcb-cursor0 libxcb1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxcb-render0
                libxcb-shape0 libxcb-shm0 libxcb-util1 libxcb-xfixes0 libxcb-xinerama0 libxcb-xinput0 libxcb-xkb1
                libxkbcommon-x11-0 python3-pip python3-venv python3-dev libsdl2-dev
                gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-gtk3 gstreamer1.0-pulseaudio
                gstreamer1.0-alsa gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly gstreamer1.0-plugins-base libnotify-dev
            )
            wxpython_deps=(
                python3-dev libgtk-3-dev gstreamer1.0-plugins-base freeglut3-dev libwebkit2gtk-4.0-dev
                libjpeg-dev libpng-dev libtiff-dev libsm-dev
            )
            ;;
        yum|dnf)
            python_build_deps=(
                gcc-c++ gcc zlib-devel ncurses-devel gdbm-devel nss-devel openssl-devel readline-devel libffi-devel bzip2-devel sqlite-devel
            )
            psychopy_basic_deps=(
                git curl libusb-devel portaudio-devel alsa-lib-devel jq
                xcb-util-cursor-devel libxcb libxcb-devel libxcb-icccm4-devel libxcb-image-devel libxcb-keysyms-devel libxcb-render-util-devel 
                libxcb-render-devel libxcb-shape-devel libxcb-shm-devel libxcb-util-devel 
                libxcb-xfixes-devel libxcb-xinerama-devel libxcb-xinput-devel libxcb-xkb-devel xkbcommon-x11-devel freeglut-devel
                python3 python3-devel SDL2-devel
                gstreamer1-libav gstreamer1-tools gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-gtk3
                gstreamer1-pulseaudio gstreamer1-alsa gstreamer1-plugins-base libnotify-devel
            )
            wxpython_deps=(
                python3-devel gtk3-devel gstreamer1-plugins-base freeglut-devel webkit2gtk3-devel
                libjpeg-turbo-devel libpng-devel libtiff-devel libSM-devel
            )
                        ;;
        pacman)
            python_build_deps=(
                base-devel zlib ncurses gdbm nss openssl readline libffi bzip2 sqlite
            )
            psychopy_basic_deps=(
                git curl libusb portaudio alsa-lib jq
                xcb-util-cursor libxcb libxcb-icccm libxcb-image libxcb-keysyms libxcb-render libxcb-render-util libxcb-shape libxcb-shm 
                libxcb-util libxcb-xfixes libxcb-xinerama libxcb-xinput libxcb-xkb xkbcommon-x11
                python sdl2 libnotify gstreamer gstreamer0.10-base gstreamer0.10-good gstreamer0.10-ugly gstreamer0.10-plugins
            )
            wxpython_deps=(
                python libgtk-3 gstreamer freeglut webkit2gtk libjpeg-turbo libpng libtiff libsm
            )
            ;;
    esac
    
    case $dep_type in
        python_build_deps)
            dependencies=("${python_build_deps[@]}")
            ;;
        psychopy_basic_deps)
            dependencies=("${psychopy_basic_deps[@]}")
            ;;
        wxpython_deps)
            dependencies=("${wxpython_deps[@]}")
            ;;
        *)
            echo "Invalid dependency type specified."
            exit 1
            ;;
    esac
    
    install_packages "$pkg_manager" "${dependencies[@]}"
}

# Function to check if the given Python version exists for download
check_python_version() {
    local version=$1
    if ! curl --output /dev/null --silent --head --fail "https://www.python.org/ftp/python/${version}/Python-${version}.tgz"; then
        echo "Python version ${version} does not exist. Exiting."
        exit 1
    fi
}

# Function to get latest pip version of package
get_latest_pypi_version() {
    local package_name=$1
    local latest_version
    latest_version=$(curl -s https://pypi.org/pypi/"$package_name"/json | jq -r .info.version)
    echo "$latest_version"
}

# Function to check if the given pip version exists for download
check_pypi_for_version() {
    local package=$1
    local version=$2
    if ! curl -s https://pypi.org/pypi/"${package}"/"${version}"/json | jq -e .info.version > /dev/null; then
        echo "${package} version ${version} does not exist. Exiting."
        exit 1
    fi
}

# Function to get the latest wxPython wheel URL
get_latest_wheel_url() {
    BASE_URL="https://extras.wxpython.org/wxPython4/extras/linux/gtk3/"
    WHEEL_DIR="${BASE_URL}${OS_VERSION}/"

    # Detect the Python version in the current virtual environment
    PYTHON_VERSION=$(python -c "import sys; print('cp' + ''.join(map(str, sys.version_info[:2])))")

    # Fetch the HTML content from the wheel directory
    HTML=$(curl -s "$WHEEL_DIR")

    WHEELS=$(echo "$HTML" | grep -oP 'href="\K[^"]*' | grep -E "${PYTHON_VERSION}.*\.whl" | grep -v ".asc" | sort)

    if [ -z "$WHEELS" ]; then
        echo "No matching wxPython wheel found for ${DISTRO} ${VERSION} and Python ${PYTHON_VERSION}."
        return 1
    fi

    LATEST_WHEEL=$(echo "$WHEELS" | tail -n 1)
    WHEEL_URL="${WHEEL_DIR}${LATEST_WHEEL}"
    echo "$WHEEL_URL"
    return 0
}
# Function to compare versions
version_greater_than() {
    [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]
}


echo "$(date "+%Y-%m-%d %H:%M:%S") - Starting the installation of PsychoPy with Python $PYTHON_VERSION"

OS_VERSION=$(detect_os_version | tr '[:upper:]' '[:lower:]')
echo "$(date "+%Y-%m-%d %H:%M:%S") - Detected ${OS_VERSION} as OS"
# Detect the package manager
pkg_manager=$(detect_package_manager)
if [ "$pkg_manager" == "none" ]; then
    echo
    echo "$(date "+%Y-%m-%d %H:%M:%S") - No compatible package manager found. Exiting."
    exit 1
fi

# Install basic dependencies
echo "$(date "+%Y-%m-%d %H:%M:%S") - Installing PsychoPy dependencies ..."
install_basic_dependencies "$pkg_manager" psychopy_basic_deps

check_python_version "${PYTHON_VERSION}"

if [ "$PSYCHOPY_VERSION" == "latest" ]; then
    PSYCHOPY_VERSION=$(get_latest_pypi_version "psychopy")
elif [ "$PSYCHOPY_VERSION" != "git" ]; then
    check_pypi_for_version psychopy "${PSYCHOPY_VERSION}"
fi

PSYCHOPY_VERSION_CLEAN=$(echo "${PSYCHOPY_VERSION}" | tr -d ',;')
PYTHON_VERSION_CLEAN=$(echo "${PYTHON_VERSION}" | tr -d ',;')

# Check PSYCHOPY_VERSION
if [ -n "$PSYCHOPY_VERSION_CLEAN" ] && ( version_greater_than "$PSYCHOPY_VERSION_CLEAN" "2023.2.3" || [ "$PSYCHOPY_VERSION_CLEAN" = "git" ] ) && { [ "$OS_VERSION" = "debian-11" ] || [ "$OS_VERSION" = "ubuntu-18.04" ]; }; then
    read -r -p "Your PsychoPy version ($PSYCHOPY_VERSION_CLEAN) is higher than 2023.2.3 or set to 'git' and might require manual fixes on $OS_VERSION. Do you want to change it to the stable version 2023.2.3? (y/N): " change_version
    if [ "$change_version" = "y" ] || [ "$change_version" = "Y" ]; then
        PSYCHOPY_VERSION_CLEAN="2023.2.3"
        echo "PsychoPy version changed to 2023.2.3."
    else
        echo "Keeping PsychoPy version $PSYCHOPY_VERSION_CLEAN."
    fi
fi

# Create PsychoPy directory
PSYCHOPY_DIR="${INSTALL_DIR}/psychopy_${PSYCHOPY_VERSION_CLEAN}_py_${PYTHON_VERSION_CLEAN}"
if [ -d "${PSYCHOPY_DIR}" ]; then
    if [ "$FORCE_OVERWRITE" = true ]; then
        echo
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Directory ${PSYCHOPY_DIR} already exists. Overwriting ..."
        rm -rf "${PSYCHOPY_DIR}"
        mkdir -p "${PSYCHOPY_DIR}"
    else
        echo
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Directory ${PSYCHOPY_DIR} already exists. Exiting."
        exit 1
    fi
else
    echo
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Creating PsychoPy directory at ${PSYCHOPY_DIR} ..."
    mkdir -p "${PSYCHOPY_DIR}"
fi
cd "${PSYCHOPY_DIR}" || exit


if [ "$BUILD_PYTHON" = true ]; then
    echo
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Building Python ${PYTHON_VERSION} from source ..."
    install_basic_dependencies "$pkg_manager" python_build_deps

    OFFICIAL_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
    TEMP_FILE="Python-${PYTHON_VERSION}.tgz"
    TEMP_DIR="Python-${PYTHON_VERSION}_temp"

    log curl -O "${OFFICIAL_URL}"
    mkdir -p "${TEMP_DIR}"
    tar -xf "${TEMP_FILE}" -C "${TEMP_DIR}"
    (
        cd "${TEMP_DIR}/Python-${PYTHON_VERSION}" || exit
        log ./configure --enable-optimizations
        log make -j "$(nproc)"
        log sudo make altinstall
    )
    log sudo rm -rf "${TEMP_DIR}" "${TEMP_FILE}"
else
    # Check if the specified Python version is already installed
    if python"${PYTHON_VERSION%.*}" --version 2>&1 | grep -q "${PYTHON_VERSION}"; then
        echo
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Python version ${PYTHON_VERSION} is already installed."
    else
        # Try to download from Nextcloud first
        echo
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Installing python build dependencies ..."
        log install_basic_dependencies "$pkg_manager" python_build_deps

        NEXTCLOUD_URL="https://cloud.uni-graz.at/index.php/s/o4tnQgN6gjDs3CK/download?path=python_${PYTHON_VERSION}_${OS_VERSION}.tar.gz"
        TEMP_FILE="python_${PYTHON_VERSION}_${OS_VERSION}.tar.gz"
        TEMP_DIR="python_${PYTHON_VERSION}_${OS_VERSION}_temp"

        echo
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Trying to download prebuild Python ${PYTHON_VERSION} for ${OS_VERSION} from Nextcloud..."
        if curl -f -X GET "${NEXTCLOUD_URL}" --output "${TEMP_FILE}"; then
            echo
            echo "$(date "+%Y-%m-%d %H:%M:%S") - Successfully downloaded Python ${PYTHON_VERSION} ... making a altinstall ..."
            mkdir -p "${TEMP_DIR}"
            tar -xf "${TEMP_FILE}" -C "${TEMP_DIR}"
            (
                cd "${TEMP_DIR}" || exit
                log sudo make altinstall
            )
            log sudo rm -rf "${TEMP_DIR}" "${TEMP_FILE}"
        else
            echo
            echo "$(date "+%Y-%m-%d %H:%M:%S") - Failed to download from Nextcloud. Building from official Python source. This might take a while ..."
            OFFICIAL_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
            TEMP_FILE="Python-${PYTHON_VERSION}.tgz"
            TEMP_DIR="Python-${PYTHON_VERSION}_temp"

            log curl -O "${OFFICIAL_URL}"
            mkdir -p "${TEMP_DIR}"
            tar -xf "${TEMP_FILE}" -C "${TEMP_DIR}"
            (
                cd "${TEMP_DIR}/Python-${PYTHON_VERSION}" || exit
                log ./configure --enable-optimizations
                log make -j "$(nproc)"
                log sudo make altinstall
            )
            log sudo rm -rf "${TEMP_DIR}" "${TEMP_FILE}"
        fi
    fi
fi

# Create and activate virtual environment
echo
echo "$(date "+%Y-%m-%d %H:%M:%S") - Creating virtual environment..."
log python"${PYTHON_VERSION%.*}" -m venv "${PSYCHOPY_DIR}"
echo
echo "$(date "+%Y-%m-%d %H:%M:%S") - Activating virtual environment..."
log source "${PSYCHOPY_DIR}/bin/activate"

# Upgrade pip and setuptools, and install wxPython
echo
echo "$(date "+%Y-%m-%d %H:%M:%S") - Upgrading pip, distro, six, and psychtoolbox ..."
log pip install -U pip
log pip install -U distro six psychtoolbox
echo


if [ "$BUILD_WX" = true ]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Building wxPython from source..."
    install_basic_dependencies "$pkg_manager" wxpython_deps
    log pip install wxpython
else
    # Check if wxPython is installed
    if python -c "import wx" &> /dev/null; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") - wxPython is already installed."
    elif pip cache list | grep -q "wxPython"; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") - A wxPython wheel is already in the pip cache. Installing from cache."
        install_basic_dependencies "$pkg_manager" wxpython_deps
        log pip install wxpython
    elif WHEEL_URL=$(get_latest_wheel_url); then
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Found matching wxPython wheel; downloading it from extras.wxpython.org"
        WHEEL_FILE=$(basename "$WHEEL_URL")
        log curl -O "$WHEEL_URL"
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Download successful. Installing wxPython from $WHEEL_FILE..."
        log pip install "$WHEEL_FILE"
        log rm "$WHEEL_FILE"
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Installed wxPython from $WHEEL_FILE"
    else
        # Try to download wxPython wheel from Nextcloud
        python_major=$(python -c "import sys; print(sys.version_info.major)")
        python_minor=$(python -c "import sys; print(sys.version_info.minor)")

        WHEEL_NAME="wxPython-0-cp${python_major}${python_minor}-cp${python_major}${python_minor}-linux_x86_64-${OS_VERSION}-${PYTHON_VERSION}.whl"

        WX_PYTHON_NEXTCLOUD_URL="https://cloud.uni-graz.at/index.php/s/YtX33kbasHMZdgs/download?path=${WHEEL_NAME}"
        WX_PYTHON_FILE="${WHEEL_NAME%-linux_x86_64*}-linux_x86_64.whl"

        echo "$(date "+%Y-%m-%d %H:%M:%S") - There is no macthing wheel on wxpython.org. Trying to download wxPython wheel from Nextcloud..."
        if curl -f -X GET "$WX_PYTHON_NEXTCLOUD_URL" --output "$WX_PYTHON_FILE"; then
            echo "$(date "+%Y-%m-%d %H:%M:%S") - Download successful. Installing wxPython from $WX_PYTHON_FILE..."
            log pip install "$WX_PYTHON_FILE"
            log rm "$WX_PYTHON_FILE"
        else
            echo "$(date "+%Y-%m-%d %H:%M:%S") - Failed to download wxPython wheel. Building wxPython from source. This might take a while ..."
            install_basic_dependencies "$pkg_manager" wxpython_deps
            log pip install wxpython
        fi
    fi
fi

# Install PsychoPy
echo
echo "$(date "+%Y-%m-%d %H:%M:%S") - Installing PsychoPy version ${PSYCHOPY_VERSION_CLEAN}"
if [ "$PSYCHOPY_VERSION" == "git" ]; then
    log pip install git+https://github.com/psychopy/psychopy
else
    log pip install psychopy=="${PSYCHOPY_VERSION_CLEAN}"
fi

# Install BIDS
if [ -n "$BIDS_VERSION" ]; then
    echo
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Installing PsychoPy-BIDS version ${BIDS_VERSION}..."
    if [ "$BIDS_VERSION" == "latest" ]; then
        BIDS_VERSION=$(get_latest_pypi_version "psychopy_bids")
    fi
    if [ "$BIDS_VERSION" == "git" ]; then
        log pip install git+https://gitlab.com/psygraz/psychopy-bids
    else
        log pip install psychopy_bids=="${BIDS_VERSION}"
    fi
    log pip install seedir
else
    echo
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Skipping PsychoPy-BIDS installation."
fi

deactivate

echo
echo "$(date "+%Y-%m-%d %H:%M:%S") - Adding ${USER} to a psychopy group and setting security limits in /etc/security/limits.d/99-psychopylimits.conf."
log sudo groupadd --force psychopy
log sudo usermod -a -G psychopy "$USER"
echo -e "@psychopy - nice -20\n@psychopy - rtprio 50\n@psychopy - memlock unlimited" | sudo tee -a /etc/security/limits.d/99-psychopylimits.conf

# Detect the shell
SHELL_NAME=$(basename "$SHELL")

# Create the bin directory
mkdir -p "${PSYCHOPY_DIR}/.bin"

# Create the symbolic link
ln -sf "${PSYCHOPY_DIR}/bin/psychopy" "${PSYCHOPY_DIR}/.bin/psychopy_${PSYCHOPY_VERSION_CLEAN}_py_${PYTHON_VERSION_CLEAN}"

case $SHELL_NAME in
    bash)
        CONFIG_FILE="$HOME/.bashrc"
        echo "export PATH=\"${PSYCHOPY_DIR}/.bin:\$PATH\"" >> "$CONFIG_FILE"
        ;;
    zsh)
        CONFIG_FILE="$HOME/.zshrc"
        echo "export PATH=\"${PSYCHOPY_DIR}/.bin:\$PATH\"" >> "$CONFIG_FILE"
        ;;
    fish)
        CONFIG_FILE="$HOME/.config/fish/config.fish"
        echo "set -gx PATH \"${PSYCHOPY_DIR}/.bin\" \$PATH" >> "$CONFIG_FILE"
        ;;
    csh|tcsh)
        CONFIG_FILE="$HOME/.${SHELL_NAME}rc"
        echo "setenv PATH ${PSYCHOPY_DIR}/.bin:\$PATH" >> "$CONFIG_FILE"
        ;;
    *)
        echo
        echo "$(date "+%Y-%m-%d %H:%M:%S") - Unsupported shell: $SHELL_NAME"
        echo
        echo "$(date "+%Y-%m-%d %H:%M:%S") - PsychoPy installation complete!"
        echo
        echo "To start PsychoPy, use:"
        echo "${PSYCHOPY_DIR}/bin/psychopy"
        exit 0
        ;;
esac

echo
echo "$(date "+%Y-%m-%d %H:%M:%S") - PsychoPy installation complete!"

echo
echo "To update your path, run:"
echo "source $CONFIG_FILE"
echo
echo "To start PsychoPy, use:"
echo "psychopy_${PSYCHOPY_VERSION_CLEAN}_py_${PYTHON_VERSION_CLEAN}"
echo
echo "If above command is not working use:"
echo "${PSYCHOPY_DIR}/bin/psychopy"
