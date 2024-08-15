#!/bin/bash
set -e
trap 'catch_errors $LINENO $BASH_COMMAND' ERR

catch_errors() {
    local lineno=$1
    local cmd=$2
    echo "Error on line $lineno: $cmd"
    exit 1
}

show_help() {
    cat << EOF
Usage: ./install_psychopy.sh [options]
Options:
  --python_version=VERSION    Specify the Python version to install (default: 3.8.19)
  --psychopy_version=VERSION  Specify the PsychoPy version to install (default: latest); use git for latest github version
  --install_dir=DIR           Specify the installation directory (default: "$HOME")
  --bids_version=VERSION      Specify the PsychoPy-BIDS version to install (default: latest); use None to skip bids installation
  --build=[python|wxpython|both] Build Python and/or wxPython from source instead of downloading
  --non-interactive           Automatically answer 'y' to all prompts
  -f, --force                 Force overwrite of existing installation directory
  -v, --verbose               Enable verbose output
  -d, --disable-shortcut      Disable desktop shortcut creation
  -h, --help                  Show this help message
EOF
}

python_version="3.8.19"
psychopy_version="latest"
install_dir="$HOME"
bids_version="latest"
force_overwrite=false
verbose=false
build_python=false
build_wx=false
disable_shortcut=false
python_version_provided=false
non_interactive=false

for arg in "$@"; do
    case $arg in
        --python_version=*)
            python_version="${arg#*=}"
            python_version_provided=true
            ;;
        --psychopy_version=*)
            psychopy_version="${arg#*=}"
            ;;
        --install_dir=*)
            install_dir="${arg#*=}"
            ;;
        --bids_version=*)
            bids_version="${arg#*=}"
            ;;
        -f|--force)
            force_overwrite=true
            ;;
        -v|--verbose)
            verbose=true
            ;;
        -d|--disable-shortcut)
            disable_shortcut=true
            ;;
        --non-interactive)
            non_interactive=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --build=*)
            build_arg="${arg#*=}"
            case $build_arg in
                python)
                    build_python=true
                    ;;
                wxpython)
                    build_wx=true
                    ;;
                both)
                    build_python=true
                    build_wx=true
                    ;;
                *)
                    echo "Invalid option for --build: $build_arg"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

prompt_user() {
    local prompt_message=$1
    if [ "$non_interactive" = true ]; then
        echo "y"
    else
        read -r -p "$prompt_message" response
        echo "$response"
    fi
}

log() {
    if [ "$verbose" = true ]; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1"
}

detect_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ -n "$VERSION_ID" ]; then
            echo "$ID-$VERSION_ID"
        else
            echo "$ID"
        fi
    elif command -v lsb_release > /dev/null 2>&1; then
        echo "$(lsb_release -si)-$(lsb_release -sr)"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "${DISTRIB_ID}-${DISTRIB_RELEASE}"
    elif [ -f /etc/debian_version ]; then
        echo "Debian-$(cat /etc/debian_version)"
    elif [ -f /etc/redhat-release ]; then
        cat /etc/redhat-release
    else
        echo "Unknown"
    fi
}

detect_package_manager() {
    if command -v apt-get > /dev/null 2>&1; then
        echo "apt"
    elif command -v yum > /dev/null 2>&1; then
        echo "yum"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman > /dev/null 2>&1; then
        echo "pacman"
    else
        echo "none"
    fi
}

update_package_manager() {
    local pkg_manager=$1
    case $pkg_manager in
        apt) log sudo apt-get update ;;
        yum) log sudo yum update -y ;;
        dnf) log sudo dnf update -y ;;
        pacman) log sudo pacman -Syu --noconfirm ;;
        *) echo "No compatible package manager found."; exit 1 ;;
    esac
}

install_packages() {
    local pkg_manager=$1
    shift
    local packages=("$@")
    
    for package in "${packages[@]}"; do
        case $pkg_manager in
            apt) log sudo apt-get install -y "$package" || echo "Package $package not found, skipping." ;;
            yum) log sudo yum install -y "$package" || echo "Package $package not found, skipping." ;;
            dnf) log sudo dnf install -y "$package" || echo "Package $package not found, skipping." ;;
            pacman) log sudo pacman -S --noconfirm "$package" || echo "Package $package not found, skipping." ;;
            *) echo "No compatible package manager found."; exit 1 ;;
        esac
    done
}

install_dependencies() {
    local pkg_manager=$1
    local dep_type=$2
    local dependencies=()

    case $pkg_manager in
        apt)
            script_deps=(git curl jq)
            psychopy_deps=(
                python3-pip make gcc libgtk-3-dev libgstreamer-gl1.0-0 libglib2.0-dev libpulse-dev
                libusb-1.0-0-dev portaudio19-dev libasound2-dev libgl1-mesa-dev libglu1-mesa-dev
                libgstreamer-plugins-base1.0-dev libjpeg-dev liblo-dev libnotify-dev libsdl2-dev
                libsm-dev libtiff-dev libxtst-dev libsndfile1-dev libportmidi-dev python3-venv
            )
            python_build_deps=(
                build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev
                libreadline-dev libffi-dev libbz2-dev libsqlite3-dev python3-dev libexpat1-dev
            )
            wxpython_deps=(python3-dev libpng-dev libtiff5-dev freeglut3-dev)
            ;;
        yum|dnf)
            script_deps=(git curl jq)
            psychopy_deps=(
                python3-pip make gcc gtk3-devel epel-release pulseaudio-libs-devel portaudio-devel
                alsa-lib-devel mesa-libGL-devel mesa-libGLU-devel gstreamer1-plugins-base-devel
                libjpeg-turbo-devel libnotify-devel SDL2-devel libSM-devel libtiff-devel
                libXtst-devel portmidi-devel xcb-util libxcb-devel
            )
            python_build_deps=(
                gcc-c++ gcc zlib-devel ncurses-devel nss-devel openssl-devel readline-devel
                libffi-devel bzip2-devel sqlite-devel python3-devel
            )
            wxpython_deps=(python3-devel freeglut-devel libpng-devel expat-devel)
            ;;
        pacman)
            script_deps=(git curl jq)
            psychopy_deps=(
                python-pip make gcc gstreamer libpulse libusb portaudio alsa-lib mesa gtk3
                libjpeg-turbo libnotify sdl2 libsm libtiff libxtst libsndfile portmidi liblo
                xcb-util python-virtualenv libxcb
            )
            python_build_deps=(
                python base-devel zlib ncurses gdbm nss openssl readline libffi bzip2 sqlite expat
            )
            wxpython_deps=(python freeglut libpng)
            ;;
        *)
            echo "No compatible package manager found."; exit 1 ;;
    esac
    
    case $dep_type in
        script_deps) dependencies=("${script_deps[@]}") ;;
        python_build_deps) dependencies=("${python_build_deps[@]}") ;;
        psychopy_deps) dependencies=("${psychopy_deps[@]}") ;;
        wxpython_deps) dependencies=("${wxpython_deps[@]}") ;;
        *) echo "Invalid dependency type specified."; exit 1 ;;
    esac

    install_packages "$pkg_manager" "${dependencies[@]}"
}

check_python_version() {
    local version=$1
    if ! curl -s --head --fail "https://www.python.org/ftp/python/${version}/Python-${version}.tgz" > /dev/null; then
        echo "Python version ${version} does not exist. Exiting."
        exit 1
    fi
}

get_latest_pypi_version() {
    local package_name=$1
    local latest_version
    latest_version=$(curl -s "https://pypi.org/pypi/${package_name}/json" | jq -r .info.version)
    if [ -z "$latest_version" ]; then
        echo "Unable to fetch the latest version for package ${package_name}. Exiting."
        exit 1
    fi
    echo "$latest_version"
}

check_pypi_for_version() {
    local package=$1
    local version=$2
    if ! curl -s "https://pypi.org/pypi/${package}/${version}/json" | jq -e .info.version > /dev/null; then
        echo "${package} version ${version} does not exist. Exiting."
        exit 1
    fi
}

get_latest_wheel_url() {
    local base_url="https://extras.wxpython.org/wxPython4/extras/linux/gtk3/"
    local wheel_dir
    local python_version_short
    local html
    local wheels
    local latest_wheel
    local wheel_url

    wheel_dir="${base_url}${os_version}/"
    python_version_short=$(python -c "import sys; print('cp' + ''.join(map(str, sys.version_info[:2])))")
    html=$(curl -s "$wheel_dir")
    wheels=$(echo "$html" | grep -oP 'href="\K[^"]*' | grep -E "${python_version_short}.*${processor_structure}.*\.whl" | grep -v ".asc" | sort)

    if [ -z "$wheels" ]; then
        echo "No matching wxPython wheel found for ${os_version}, Python ${python_version_short}, and ${processor_structure}."
        return 1
    fi

    latest_wheel=$(echo "$wheels" | tail -n 1)
    wheel_url="${wheel_dir}${latest_wheel}"

    echo "$wheel_url"
    return 0
}

version_greater_than() {
    [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]
}

create_desktop_file() {
    local exec_args=$1
    local pretty_name=$2
    local desktop_file="${desktop_shortcut}${pretty_name}.desktop"
    
    {
        echo "[Desktop Entry]"
        echo "Version=1.0"
        echo "Name=${pretty_name}"
        echo "Comment=Run PsychoPy version ${psychopy_version_clean} with ${exec_args}"
        echo "Exec=${psychopy_exec} ${exec_args}"
        [ -n "$icon_file" ] && echo "Icon=${icon_file}"
        echo "Terminal=false"
        echo "Type=Application"
        echo "Categories=Education;Science;"
    } > "$desktop_file"
    
    chmod +x "$desktop_file"
    gio set "$desktop_file" metadata::trusted true
    echo "$desktop_file"
}




os_version=$(detect_os_version | tr '[:upper:]' '[:lower:]')
processor_structure=$(uname -s | tr '[:upper:]' '[:lower:]')_$(uname -m)
log_message "Initiating PsychoPy installation with Python $python_version on ${os_version} (${processor_structure} architecture)."


pkg_manager=$(detect_package_manager)
if [ "$pkg_manager" == "none" ]; then
    log_message "No compatible package manager found. Exiting."
    exit 1
fi

log_message "Updating ${pkg_manager} package manager."
update_package_manager "$pkg_manager"

log_message "Installing git, curl, and jq."
install_dependencies "$pkg_manager" script_deps

if [ "$psychopy_version" == "latest" ]; then
    psychopy_version=$(get_latest_pypi_version "psychopy")
elif [ "$psychopy_version" != "git" ]; then
    check_pypi_for_version psychopy "${psychopy_version}"
fi

if [ "$psychopy_version" == "git" ]; then
    latest_version=$(curl -s https://api.github.com/repos/psychopy/psychopy/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    log_message "The latest PsychoPy github version is: $latest_version"
    psychopy_version_clean=$(echo "${latest_version}" | tr -d ',;')
else
    psychopy_version_clean=$(echo "${psychopy_version}" | tr -d ',;')
fi

if [ -n "$psychopy_version_clean" ] && ( version_greater_than "$psychopy_version_clean" "2023.2.3" || [ "$psychopy_version_clean" = "git" ] ) && { [ "$os_version" = "debian-11" ] || [ "$os_version" = "ubuntu-18.04" ]; }; then
    prompt_message="Your PsychoPy version ($psychopy_version_clean) is higher than 2023.2.3 or set to 'git' and might require manual fixes on $os_version. Do you want to change it to the stable version 2023.2.3? (y/N): "
    change_version=$(prompt_user "$prompt_message")
    if [[ "$change_version" =~ ^[Yy]$ ]]; then
        psychopy_version_clean="2023.2.3"
        log_message "PsychoPy version changed to 2023.2.3."
    else
        log_message "Keeping PsychoPy version $psychopy_version_clean."
    fi
fi

if ! $python_version_provided; then
    python_system_version=$(python3 --version 2>&1)
    if [[ $python_system_version =~ Python\ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        patch=${BASH_REMATCH[3]}

        if (( major == 3 && minor >= 8 && minor < 11 )); then
            log_message "Python version $major.$minor.$patch is already installed and is within the specified range."
            prompt_message="Do you want to use the existing Python version $major.$minor.$patch? (y/N): "
            use_existing_python=$(prompt_user "$prompt_message")
            if [[ "$use_existing_python" =~ ^[Yy]$ ]]; then
                python_version="$major.$minor.$patch"
                log_message "Using existing Python version $python_version."
            else
                log_message "Using default Python version $python_version."
            fi
        else
            log_message "Installed Python version $major.$minor.$patch is not within the specified range. Using default Python version $python_version."
        fi
    else
        log_message "Python version could not be determined. Using default Python version $python_version."
    fi
else
    check_python_version "${python_version}"
fi
python_version_clean=$(echo "${python_version}" | tr -d ',;')

psychopy_dir="${install_dir}/psychopy_${psychopy_version_clean}_py_${python_version_clean}"
if [ -d "${psychopy_dir}" ]; then
    if [ "$force_overwrite" = true ]; then
        log_message "Directory ${psychopy_dir} already exists. Overwriting ..."
        rm -rf "${psychopy_dir}"
        mkdir -p "${psychopy_dir}"
    else
        log_message "Directory ${psychopy_dir} already exists. Exiting."
        exit 1
    fi
else
    log_message "Creating PsychoPy directory at ${psychopy_dir} ..."
    mkdir -p "${psychopy_dir}"
fi
cd "${psychopy_dir}" || { log_message "Failed to change directory to ${psychopy_dir}. Exiting."; exit 1; }


log_message "Installing PsychoPy dependencies. This might take a while ..."
install_dependencies "$pkg_manager" psychopy_deps

if python"${python_version%.*}" --version 2>&1 | grep -q "${python_version}"; then
    log_message "Python version ${python_version} is already installed."
else
    log_message "Installing python build dependencies ..."
    log install_dependencies "$pkg_manager" python_build_deps
    if [ "$build_python" = true ]; then
        log_message "Building Python ${python_version} from source ..."

        official_url="https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz"
        temp_file="Python-${python_version}.tgz"
        temp_dir="Python-${python_version}_temp"

        log curl -O "${official_url}"
        mkdir -p "${temp_dir}"
        tar -xf "${temp_file}" -C "${temp_dir}"
        (
            cd "${temp_dir}/Python-${python_version}" || exit
            log ./configure --enable-optimizations --with-ensurepip=install
            log make -j "$(nproc)"
            log sudo make altinstall
        )
        log sudo rm -rf "${temp_dir}" "${temp_file}"
    else
        nextcloud_url="https://cloud.uni-graz.at/index.php/s/o4tnQgN6gjDs3CK/download?path=python-${python_version}-${processor_structure}-${os_version}.tar.gz"
        temp_file="python-${python_version}-${processor_structure}-${os_version}.tar.gz"
        temp_dir="python-${python_version}-${processor_structure}-${os_version}_temp"

        log_message "Trying to download prebuilt Python ${python_version} for ${os_version} ${processor_structure} from Nextcloud ($nextcloud_url)..."
        if curl -f -X GET "${nextcloud_url}" --output "${temp_file}"; then
            log_message "Successfully downloaded Python ${python_version} ... making a altinstall ..."
            mkdir -p "${temp_dir}"
            tar -xf "${temp_file}" -C "${temp_dir}"
            (
                cd "${temp_dir}" || exit
                log sudo make altinstall
            )
            log sudo rm -rf "${temp_dir}" "${temp_file}"
        else
            log_message "Failed to download from Nextcloud. Building from official Python source. This might take a while ..."
            official_url="https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz"
            temp_file="Python-${python_version}.tgz"
            temp_dir="Python-${python_version}_temp"

            log curl -O "${official_url}"
            mkdir -p "${temp_dir}"
            tar -xf "${temp_file}" -C "${temp_dir}"
            (
                cd "${temp_dir}/Python-${python_version}" || exit
                log ./configure --enable-optimizations --with-ensurepip=install
                log make -j "$(nproc)"
                log sudo make altinstall
            )
            log sudo rm -rf "${temp_dir}" "${temp_file}"
        fi
    fi
fi

if ! command -v python"${python_version%.*}" &> /dev/null; then
    log_message "Error: python${python_version%.*} not found. Something went wrong while installing/building. Try --build=python and --verbose as arguments."
    exit 1
fi

log_message "Creating and activating virtual environment..."
log python"${python_version%.*}" -m venv "${psychopy_dir}"
log source "${psychopy_dir}/bin/activate"

log_message "Upgrading pip, distro, six, psychtoolbox and attrdict ..."
log pip install -U pip distro six psychtoolbox attrdict

if version_greater_than "2024.2.0" "$psychopy_version_clean"; then
    log_message "PsychoPy version < 2024.2.0, installing numpy<2"
    log pip install "numpy<2"
fi

if [ "$build_wx" = true ]; then
    log_message "Building wxPython from source. This might take a while ..."
    install_dependencies "$pkg_manager" wxpython_deps
    log pip install wxpython
else
    if python -c "import wx" &> /dev/null; then
        log_message "wxPython is already installed."
    elif pip cache list | grep -q "wxPython"; then
        log_message "A wxPython wheel is already in the pip cache. Installing from cache."
        log pip install wxpython
    elif wheel_url=$(get_latest_wheel_url); then
        wheel_file=$(basename "$wheel_url")
        log_message "Found matching wxPython wheel; downloading it from extras.wxpython.org ($wheel_url)"
        log curl -O "$wheel_url"
        log_message "Download successful. Installing wxPython from $wheel_file..."
        log pip install "$wheel_file"
        log rm "$wheel_file"
        log_message "Installed wxPython from $wheel_file"
    else
        python_major=$(python -c "import sys; print(sys.version_info.major)")
        python_minor=$(python -c "import sys; print(sys.version_info.minor)")

        wxpython_version=$(get_latest_pypi_version wxpython)

        wheel_name="wxPython-${wxpython_version}-cp${python_major}${python_minor}-cp${python_major}${python_minor}-${processor_structure}-${os_version}.whl"
        wheel_name_fallback="wxPython-4.2.1-cp${python_major}${python_minor}-cp${python_major}${python_minor}-${processor_structure}-${os_version}.whl"
        wx_python_nextcloud_url="https://cloud.uni-graz.at/index.php/s/YtX33kbasHMZdgs/download?path=${wheel_name}"
        wx_python_nextcloud_url_fallback="https://cloud.uni-graz.at/index.php/s/YtX33kbasHMZdgs/download?path=${wheel_name_fallback}"
        
        wx_python_file="${wheel_name%-"${os_version}".whl}.whl"

        log_message "There is no matching wheel on wxpython.org. Trying to download wxPython wheel from Nextcloud ($wx_python_nextcloud_url)"
        if curl -f -X GET "$wx_python_nextcloud_url" --output "$wx_python_file" || curl -f -X GET "$wx_python_nextcloud_url_fallback" --output "$wx_python_file"; then
            log_message "Download successful. Installing wxPython from $wx_python_file..."
            log pip install "$wx_python_file"
            log rm "$wx_python_file"
        else
            log_message "Failed to download wxPython wheel. Building wxPython from source. This might take a while ..."
            install_dependencies "$pkg_manager" wxpython_deps
            log pip install wxpython
        fi
    fi
fi

log_message "Installing PsychoPy version ${psychopy_version_clean}"
if [ "$psychopy_version" == "git" ]; then
    log pip install git+https://github.com/psychopy/psychopy
else
    log pip install psychopy=="${psychopy_version_clean}"
fi

if [ "$bids_version" != "None" ]; then
    log_message "Installing PsychoPy-BIDS version ${bids_version}..."
    if [ "$bids_version" == "latest" ]; then
        bids_version=$(get_latest_pypi_version "psychopy_bids")
    fi
    if [ "$bids_version" == "git" ]; then
        log pip install git+https://gitlab.com/psygraz/psychopy-bids
    else
        check_pypi_for_version psychopy_bids "${bids_version}"
        log pip install psychopy_bids=="${bids_version}"
    fi
    log pip install seedir
else
    log_message "Skipping PsychoPy-BIDS installation."
fi

deactivate

log_message "Adding ${USER} to psychopy group and setting security limits in /etc/security/limits.d/99-psychopylimits.conf."
log sudo groupadd --force psychopy
log sudo usermod -a -G psychopy "$USER"
sudo sh -c 'echo "@psychopy - nice -20\n@psychopy - rtprio 50\n@psychopy - memlock unlimited" > /etc/security/limits.d/99-psychopylimits.conf'

if [ "$disable_shortcut" = false ]; then
    desktop_shortcut="${HOME}/Desktop/"
    if [ -d "$desktop_shortcut" ]; then
        desktop_dir="${HOME}/.local/share/applications/"
        psychopy_exec="${psychopy_dir}/bin/psychopy"
        icon_url="https://raw.githubusercontent.com/psychopy/psychopy/master/psychopy/app/Resources/psychopy.png"
        icon_file="${psychopy_dir}/psychopy.png"

        if curl --output /dev/null --silent --head --fail "$icon_url"; then
            log curl -o "$icon_file" "$icon_url"
        fi

        if [ ! -f "$icon_file" ]; then
            log_message "PsychoPy icon not found. Skipping icon setting."
            icon_file=""
        fi

        pretty_name_no_args="PsychoPy (v${psychopy_version_clean}) python(v${python_version_clean})"
        pretty_name_coder="PsychoPy Coder (v${psychopy_version_clean}) python(v${python_version_clean})"
        pretty_name_builder="PsychoPy Builder (v${psychopy_version_clean}) python(v${python_version_clean})"

        file_no_args=$(create_desktop_file "" "$pretty_name_no_args")
        file_coder=$(create_desktop_file "--coder" "$pretty_name_coder")
        file_builder=$(create_desktop_file "--builder" "$pretty_name_builder")

        if [ -d "$desktop_dir" ]; then
            ln -sf "$file_no_args" "${desktop_dir}${pretty_name_no_args}.desktop"
            ln -sf "$file_coder" "${desktop_dir}${pretty_name_coder}.desktop"
            ln -sf "$file_builder" "${desktop_dir}${pretty_name_builder}.desktop"
        else
            log_message "Applications directory $desktop_dir does not exist. Skipping application menu shortcut creation."
        fi
    else
        log_message "Desktop directory $desktop_shortcut does not exist. Skipping desktop shortcut creation."
    fi
else
    log_message "Desktop shortcut creation disabled by user."
fi


shell_name=$(basename "$SHELL")
mkdir -p "${psychopy_dir}/.bin"
ln -sf "${psychopy_dir}/bin/psychopy" "${psychopy_dir}/.bin/psychopy_${psychopy_version_clean}_py_${python_version_clean}"

case $shell_name in
    bash)
        config_file="$HOME/.bashrc"
        echo "export PATH=\"${psychopy_dir}/.bin:\$PATH\"" >> "$config_file"
        ;;
    zsh)
        config_file="$HOME/.zshrc"
        echo "export PATH=\"${psychopy_dir}/.bin:\$PATH\"" >> "$config_file"
        ;;
    fish)
        config_file="$HOME/.config/fish/config.fish"
        echo "set -gx PATH \"${psychopy_dir}/.bin\" \$PATH" >> "$config_file"
        ;;
    csh|tcsh)
        config_file="$HOME/.${shell_name}rc"
        echo "setenv PATH ${psychopy_dir}/.bin:\$PATH" >> "$config_file"
        ;;
    *)
        log_message "Unsupported shell: $shell_name"
        echo
        log_message "PsychoPy installation complete!"
        echo
        echo "To start PsychoPy, use:"
        echo "${psychopy_dir}/bin/psychopy"
        exit 0
        ;;
esac

echo
log_message "PsychoPy installation complete!"
echo
echo "To update your path, run:"
echo "source $config_file"
echo
echo "To start PsychoPy from terminal, use:"
echo "psychopy_${psychopy_version_clean}_py_${python_version_clean}"
echo
echo "You can also use your desktop-icons if they are created successfully."
echo "If the above command or desktop-icons are not working, use:"
echo "${psychopy_dir}/bin/psychopy"