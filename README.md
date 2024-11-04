# PsychoPy Installation Script for Linux

This script facilitates the installation of [PsychoPy](https://www.psychopy.org/) on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04, (18.04)
- Pop!_OS 22.04
- Debian 12, 11
- Fedora 40, 39
- Rocky Linux 9
- CentOS 9
- Linux Mint 22
- OpenSuse 16
- Manjaro 22

These distributions have been tested for compatibility, but the script may also work on other Linux distributions.

**Note:**
Ubuntu-18.04 fails to install PyQt6. You can still use Ubuntu-18 with PsychoPy versions =< 2023.2.3. Earlier versions use PyQt5.

## Important Information

- PsychoPy supports Python versions 3.8, 3.9, and 3.10.
- Default(3.10)/specified Python version is installed as `altinstall` into `/usr/local/psychopy_python` if not available via package manager.
- A directory is created in the specified directory (default: `$HOME`): `{install_dir}/psychopy_${PSYCHOPY_VERSION}_py${PYTHON_VERSION}`.
- The script attempts to install Python via the package manager; if not found, it downloads a pre-packaged .tar.gz from GitHub releases or, if unavailable, from python.org to build from source.
- wxPython is downloaded from the [official site](https://extras.wxpython.org/wxPython4/extras/linux/gtk3/); if this fails, the script tries GitHub releases or builds from source.
- After successful wxPython installation, the downloaded .whl file is cached in `/usr/local/psychopy_python/wx_wheels`.
- If the downloads fail, building Python and wxPython may take a some time.
- The script provides minimal output by default. Use the `--verbose` option for detailed logging.

## Usage

Install curl with your package manger. On most distros curl is already installed.

Download and execute the script:

```bash
 curl -o- https://raw.githubusercontent.com/wieluk/psychopy_linux_installer/main/psychopy_linux_installer | bash
```

Using arguments:

```bash
 curl -o- https://raw.githubusercontent.com/wieluk/psychopy_linux_installer/main/psychopy_linux_installer | bash -s -- --sudo-mode=auto
```

## Options

| Option | Description |
|--------|-------------|
| `--psychopy-version=`<br>`VERSION` | Specify the [PsychoPy Version](https://pypi.org/project/psychopy/#history) to install (default: `latest`). |
| `--python-version=`<br>`[3.8\|3.9\|3.10]` | Specify the [Python Version](https://www.python.org/ftp/python) to install (default: `3.10`). |
| `--wxpython-version=`<br>`VERSION` | Specify the [wxPython Version](https://pypi.org/project/wxPython/#history) to install (default: `4.2.2`). |
| `--build=`<br>`[python\|wxpython\|both]` | Build Python and/or wxPython from source instead of downloading wheel/binaries. Use `both` if something does not work. |
| `--install-dir=DIR` | Specify the installation directory (default: `$HOME`); use absolute paths without a trailing `/`. Do not use `~/`; use `/home/{user}` instead. |
| `--no-versioned-install-dir` | Installs directly into the specified `install-dir` without creating a versioned subdirectory. Requires `--install-dir`. |
| `--additional-packages=`<br>`PACKAGES` | Specify additional pip packages to install. Format: package1==version,package2. No extra packages are installed if not set. |
| `--sudo-mode=`<br>`[ask\|auto\|error\|continue\|force]` | Control sudo usage. ask: confirm, auto: auto-confirm, error: exit if sudo needed, continue: continue without sudo, force: use sudo directly. (default: `ask`) |
| `--disable-shortcut` | Disable desktop shortcut creation. |
| `--disable-path` | Disable adding psychopy to system path. |
| `-f`, `--force` | Force overwrite of the existing installation directory. |
| `-v`, `--verbose` | Enable verbose output. |
| `-h`, `--help` | Show help message. |

**Note:**

- Non-Admin Installation: The `--sudo-mode=continue` option enables non-admin users to upgrade or reinstall if the required Python version and packages are already installed. This option assumes an administrator has previously run the installation.
- Version Selection: The `--psychopy-version` and `--wxpython-version` options accept specific versions from [PyPI](https://pypi.org), as well as `latest` or `git`. Note that `git` versions may be unstable and are generally not recommended.

## Example

```bash
curl -o https://raw.githubusercontent.com/wieluk/psychopy_linux_installer/main/psychopy_linux_installer | bash -s -- --psychopy-version=2024.2.4 --python-version=3.10 --install-dir=/home/user1 --additional-packages=psychopy_bids,seedir,psychopy-crs==0.0.2 --sudo-mode=auto --build=python --verbose --force
```

## Script Details

The script performs the following steps:

- Detects the package manager (supports apt, yum, dnf, pacman and zypper).
- Installs necessary dependencies.
- Creates a directory in the specified location for PsychoPy.
- Checks if the specified Python version exists if necessary downloads and install it as `altinstall`.
- Creates and activates a virtual environment for PsychoPy.
- Installs/builds wxPython.
- Upgrades pip and some pip packages.
- Installs specified PsychoPy version.
- Adds the current user to a `psychopy` group and sets security limits.
- Creates a symbolic link to the PsychoPy executable in `.bin`.
- Creates a desktop shortcut.

## Post-Installation

After installation, desktop icons for PsychoPy will be created automatically, and the application will be added to your system's PATH as:

`psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`

You can also launch PsychoPy directly using the absolute path:

`${PSYCHOPY_DIR}/bin/psychopy`

Please reboot to apply security limits and to refresh system path.

**Note:**
All commands, along with the installed versions and set paths will be displayed at the end of the script.

## Uninstalling PsychoPy

To completely uninstall PsychoPy, you’ll need to remove the application files, shortcuts, and (optionally) dependencies installed for PsychoPy.

### Remove PsychoPy Application Files

By default, PsychoPy installs its files in the following directories:

- **PsychoPy installation directory**: `~/psychopy_${PSYCHOPY_VERSION}_py${PYTHON_VERSION}`
- **Python and wxPython packages**: `/usr/local/psychopy_python`

To uninstall PsychoPy, delete both of these directories:

```bash
#rm -rf {install_dir}/psychopy_${PSYCHOPY_VERSION}_py${PYTHON_VERSION} #use your version and install_dir default is $home directory
sudo rm -rf /usr/local/psychopy_python
```

### Remove Desktop Shortcuts

PsychoPy creates desktop shortcuts that you can safely delete. To remove all PsychoPy shortcuts, use:

```bash
rm ~/.local/share/applications/PsychoPy*.desktop
#rm ~/Desktop/PsychoPy*.desktop #might be different if you do not have your language set to english
```

### Remove PsychoPy from the System Path

During installation, a line is added to the end of your shell’s configuration file. The line typically looks like:

```bash
export PATH="{install_dir}/psychopy_${PSYCHOPY_VERSION}_py${PYTHON_VERSION}/.bin:$PATH"
```

Locate and edit the configuration file for your shell to remove this line:

- **Bash**: `$HOME/.bashrc`
- **Zsh**: `$HOME/.zshrc`
- **Fish**: `$HOME/.config/fish/config.fish`
- **Csh**: `$HOME/.Cshrc`
- **Csh/Tcsh**: `$HOME/.Tcshrc`

### (Optional): Remove Dependencies

Dependencies for PsychoPy and for building Python/WxPython are installed via package manager.

**Warning**: Removing dependencies can affect other applications. If you’re unsure, do not touch them.

<details>
  <summary>Uninstall dependencies by package manager</summary>

Depending on the installation not all dependencies are installed. `script_deps` and `psychopy_deps` are always installed.

Here are all dependencies listed that might be installed:

```bash
apt-get)
    script_deps=(git curl jq)
    psychopy_deps=(libgtk-3-dev libwebkit2gtk-4.0-dev libwebkit2gtk-4.1-dev libxcb-xinerama0 libegl1-mesa-dev libsdl2-dev libglu1-mesa-dev libusb-1.0-0-dev portaudio19-dev libasound2-dev libxcb-cursor0 libxkbcommon-x11-0)
    python_build_deps=(build-essential libssl-dev zlib1g-dev libsqlite3-dev libffi-dev libbz2-dev libreadline-dev xz-utils make)
    wxpython_deps=(libjpeg-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x freeglut3-dev libpng-dev libtiff-dev libnotify-dev libsm-dev libgtk2.0-dev g++ make libglib2.0-dev)
    python_with_venv=(python3 python3-venv python3-pip python3-dev)
    ;;
yum|dnf)
    script_deps=(git curl jq)
    psychopy_deps=(gtk3-devel webkit2gtk3-devel libxcb-xinerama mesa-libEGL-devel SDL2-devel mesa-libGLU-devel libusb1-devel portaudio-devel alsa-lib-devel)
    python_build_deps=(gcc openssl-devel bzip2-devel libffi-devel zlib-devel sqlite-devel readline-devel xz-devel make)
    wxpython_deps=(libjpeg-devel libpng-devel libSM-devel gcc-c++ gstreamer1-plugins-base gstreamer1-devel freeglut-devel libjpeg-turbo-devel libpng-devel libtiff-devel libnotify-devel gtk2-devel make glib2-devel)
    python_with_venv=(python3 python3-venv python3-pip python3-devel)
    ;;
pacman)
    script_deps=(git curl jq)
    psychopy_deps=(gtk3 webkit2gtk libxcb mesa sdl2 glu libusb portaudio alsa-lib)
    python_build_deps=(base-devel openssl zlib sqlite libffi bzip2 readline xz make)
    wxpython_deps=(libjpeg libpng libsm mesa gstreamer gstreamer-base freeglut libtiff libnotify gtk2 gcc make glib2)
    python_with_venv=(python python-virtualenv python-pip)
    ;;
zypper)
    script_deps=(git curl jq)
    psychopy_deps=(gtk3-devel libxcb-xinerama0 libSDL2-devel libusb-1_0-devel portaudio-devel alsa-devel)
    python_build_deps=(gcc libopenssl-devel zlib-devel sqlite3-devel libffi-devel bzip2-devel readline-devel xz-devel make)
    wxpython_deps=(libpng16-devel gstreamer-plugins-base freeglut-devel libnotify-devel libSM-devel gtk2-devel gcc-c++ make glib2-devel)
    python_with_venv=(python3 python3-virtualenv python3-pip python3-devel)
```
</details>

## Automated Installation, Test and build Results

[View the latest installation test results](https://github.com/wieluk/psychopy_linux_installer/blob/main/.github/installation_results.md)

[View the build results](https://github.com/wieluk/psychopy_linux_installer/blob/main/.github/build_results.md)

## Links

- [PsychoPy Github](https://github.com/psychopy/psychopy)
