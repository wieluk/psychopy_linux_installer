# PsychoPy Installation Script for Linux

This script facilitates the installation of [PsychoPy](https://www.psychopy.org/) on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04, (18.04)
- Pop!_OS 22.04
- Debian 12, 11
- Fedora 41, 40, 39
- Rocky Linux 9
- CentOS 9
- Linux Mint 22
- OpenSuse 15
- Manjaro 25

These distributions have been tested for compatibility, but the script may also work on other Linux distributions.

**Notes:**

- Ubuntu-18.04 fails to install PyQt6. You can still use Ubuntu-18 with PsychoPy versions =< 2023.2.3. Earlier versions use PyQt5.
- Arch Linux worked in my testing. I had to increase /tmp size to be bigger than 2GB, and since there are no prebuilt wxPython wheels for Arch, it has to be built from source.

## Important Information

- This script will install multiple dependencies based on your Linux distribution. A detailed list of packages that may be installed is available [here](#optional-remove-dependencies) (click "Uninstall dependencies by package manager" to expand).
- PsychoPy supports Python versions 3.8, 3.9, and 3.10.
- A directory is created at `{install_dir}/psychopy_${PSYCHOPY_VERSION}_py${PYTHON_VERSION}` (`--install-dir`, default: `$HOME`). Use `--venv-name=NAME` to replace the versioned subdirectory with a custom name (`{install_dir}/${NAME}`).
- The script attempts to install Python via the package manager; if not found, it downloads a pre-packaged .tar.gz from GitHub releases or, if unavailable, from python.org to build from source.
- Default(3.10)/specified Python version is installed as `altinstall` into `/usr/local/psychopy_python` if not available via package manager.
- wxPython is downloaded from the [official site](https://extras.wxpython.org/wxPython4/extras/linux/gtk3/); if this fails, the script tries GitHub releases or builds from source.
- After successful wxPython installation, the downloaded .whl file is cached in `/usr/local/psychopy_python/wx_wheels`.
- If the downloads fail, building Python and wxPython may take a some time.
- The script provides minimal output to terminal. Use the `--verbose` option for detailed logging (logfile output is always verbose).
- Logs are written to a timestamped file in `/tmp/psychopy_linux_installer_YYYYMMDD_HHMMSS.log` first and then moved into the `install-dir`.

## Usage

Install curl with your package manger. On most distros curl is already installed.

1. **Download the script:**

   ```bash
   curl -LOs https://github.com/wieluk/psychopy_linux_installer/releases/latest/download/psychopy_linux_installer
   ```

2. **Make it executable:**

   ```bash
   chmod +x psychopy_linux_installer
   ```

3. **Run the installer:**
    - **GUI Mode**:

      ```bash
      ./psychopy_linux_installer --gui
      ```

       `curl` and `zenity` are required for the GUI mode.

    - **Command-Line Mode**:

      ```bash
      ./psychopy_linux_installer
      ```

## Options

| Option | Description |
|--------|-------------|
| `--psychopy-version=`<br>`VERSION` | Specify the [PsychoPy Version](https://pypi.org/project/psychopy/#history) to install (default: `latest`). |
| `--python-version=`<br>`[3.8\|3.9\|3.10]` | Specify the [Python Version](https://www.python.org/ftp/python) to install (default: `3.10`). |
| `--wxpython-version=`<br>`VERSION` | Specify the [wxPython Version](https://pypi.org/project/wxPython/#history) to install (default: `4.2.2`). |
| `--build=`<br>`[python\|wxpython\|both]` | Build Python and/or wxPython from source instead of downloading wheel/binaries. Not recommended, as the script will automatically fall back to building from source if downloading fails. This option is intended for cases where the script does not fail, but the installation does not work as expected. |
| `--install-dir=DIR` | Specify the installation directory (default: `$HOME`); use absolute paths without a trailing `/`. Do not use `~/`; use `/home/{user}` instead. |
| `--venv-name=NAME` | Specify a custom name for the virtual environment folder. If omitted, a versioned subdirectory will be used by default. Spaces in the name will be replaced with underscores (_). |
| `--additional-packages=`<br>`PACKAGES` | Specify additional pip packages to install. Format: package1==version,package2. No extra packages are installed if not set. |
| `--sudo-mode=`<br>`[ask\|auto\|error\|continue\|force]` | Control sudo usage. ask: confirm, auto: auto-confirm, error: exit if sudo needed, continue: continue without sudo, force: use sudo directly. (default: `ask`) |
| `--disable-shortcut` | Disable desktop shortcut creation. |
| `--disable-path` | Disable adding psychopy to system path. |
| `--non-interactive` | Run the installer without user interaction. Sets `sudo-mode` to `auto` if not set. |
| `--gui` | Launches the installer in GUI mode, allowing you to set arguments interactively. Any arguments provided via the command line will be ignored while in GUI mode. |
| `-f`, `--force` | Force overwrite of the existing installation directory. |
| `-v`, `--verbose` | Enable verbose output for the terminal (logfile output is always verbose). |
| `-h`, `--help` | Show help message. |

**Note:**

- Non-Admin Installation: The `--sudo-mode=continue` option enables non-admin users to upgrade or reinstall if the required Python version and packages are already installed. This option assumes an administrator has previously run the installation.
- Version Selection: The `--psychopy-version` and `--wxpython-version` options accept specific versions from [PyPI](https://pypi.org), as well as `latest` or `git`. Note that `git` versions may be unstable and are generally not recommended.

## Example

```bash
./psychopy_linux_installer --psychopy-version=2024.2.4 --python-version=3.10 --install-dir=/home/user1 --venv-name=custom-psychopy --additional-packages=psychopy_bids,seedir,psychopy-crs==0.0.2 --sudo-mode=auto --build=python --verbose --force
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

To completely remove PsychoPy, you’ll need to delete its virtual environment folder, shortcuts, settings folder, and optionally, any dependencies installed for PsychoPy.

### Removing the PsychoPy Virtual Environment Folder

By default, PsychoPy installs its files in the following locations:

- **PsychoPy installation directory:** `~/psychopy_${PSYCHOPY_VERSION}_py${PYTHON_VERSION}`
- **PsychoPy’s Python and wxPython:** `/usr/local/psychopy_python`

To uninstall PsychoPy, delete both directories:

```bash
# rm -rf {install_dir}/psychopy_${PSYCHOPY_VERSION}_py${PYTHON_VERSION}  # Use your version/venv-name and install_dir (default is the home directory)
sudo rm -rf /usr/local/psychopy_python
```  

### Remove the PsychoPy settings folder

PsychoPy stores its user-specific settings and preferences in the ~/.psychopy3 directory.

To remove it, run:

```bash
rm -rf ~/.psychopy3
```

### Remove Desktop Shortcuts

The PsychoPy installer creates desktop shortcuts that you can safely delete. To remove all PsychoPy shortcuts, use:

```bash
rm ~/.local/share/applications/PsychoPy*.desktop
#rm ~/Desktop/PsychoPy*.desktop # Might be different if you do not have your language set to english
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
- **Tcsh**: `$HOME/.Tcshrc`

### (Optional): Remove Dependencies

Dependencies for PsychoPy and for building Python/WxPython are installed via package manager.

**⚠ Warning ⚠**: Removing dependencies can affect other applications. If you’re unsure, do not touch them.

<details>
  <summary>Uninstall dependencies by package manager</summary>

Depending on the installation not all dependencies are installed. `script_deps` and `psychopy_deps` are always installed.

Here are all dependencies listed that might be installed:

```text
apt-get
    script_deps=(curl git jq)
    psychopy_deps=(libasound2-dev libegl1-mesa-dev libglib2.0-dev libgtk-3-dev libnotify4 libusb-1.0-0-dev libwebkit2gtk-4.0-dev libwebkit2gtk-4.1-dev libxcb-cursor0 libxcb-xinerama0 libxkbcommon-x11-0 libsdl2-dev libglu1-mesa-dev portaudio19-dev pulseaudio pulseaudio-utils)
    fonts=(fonts-dejavu fonts-liberation fontconfig)
    python_build_deps=(build-essential libbz2-dev libffi-dev libreadline-dev libsqlite3-dev libssl-dev make xz-utils zlib1g-dev)
    wxpython_deps=(freeglut3-dev g++ gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x libgtk2.0-dev libjpeg-dev libnotify-dev libpng-dev libsm-dev libtiff-dev make)
    python_with_venv=(python3 python3-dev python3-pip python3-venv)

yum|dnf
    script_deps=(curl git jq)
    psychopy_deps=(alsa-lib-devel gtk3-devel libnotify mesa-libEGL-devel mesa-libGLU-devel portaudio-devel pulseaudio pulseaudio-utils SDL2-devel webkit2gtk3-devel webkit2gtk4.0-devel libusb1-devel)
    fonts=(fontconfig dejavu-sans-fonts dejavu-serif-fonts liberation-sans-fonts liberation-serif-fonts liberation-mono-fonts)
    python_build_deps=(bzip2-devel gcc libffi-devel make openssl-devel readline-devel sqlite-devel xz-devel zlib-devel)
    wxpython_deps=(freeglut-devel gcc-c++ gstreamer1-devel gtk2-devel libSM-devel libjpeg-devel libjpeg-turbo-devel libnotify-devel libpng-devel libtiff-devel make glib2-devel)
    python_with_venv=(python3 python3-devel python3-pip python3-venv)

pacman
    script_deps=(curl git jq)
    psychopy_deps=(alsa-lib gtk3 libnotify libusb mesa portaudio pulseaudio pulseaudio-utils SDL2 webkit2gtk xcb-util-cursor libxcb glu)
    fonts=(dejavu ttf-liberation noto-fonts gnu-free-fonts)
    python_build_deps=(base-devel bzip2 libffi make openssl readline sqlite xz zlib)
    wxpython_deps=(freeglut gcc glib2 gstreamer gtk2 libjpeg libpng libsm libtiff make mesa)
    python_with_venv=(python python-pip python-virtualenv)

zypper
    script_deps=(curl git jq)
    psychopy_deps=(alsa-devel gtk3-devel libnotify4 libusb-1_0-devel libxcb-xinerama0 portaudio-devel pulseaudio pulseaudio-utils SDL2-devel)
    fonts=(dejavu-fonts liberation-fonts fontconfig)
    python_build_deps=(gcc libffi-devel libopenssl-devel make readline-devel sqlite3-devel xz-devel zlib-devel)
    wxpython_deps=(freeglut-devel gcc-c++ glib2-devel gstreamer-plugins-base libSM-devel libjpeg-turbo libnotify-devel libpng16-devel make libtiff-devel)
    python_with_venv=(python3 python3-devel python3-pip python3-virtualenv)
```

</details>
