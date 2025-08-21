# PsychoPy Installation Script for Linux

[![GitHub Release](https://img.shields.io/github/v/release/wieluk/psychopy_linux_installer)](https://github.com/wieluk/psychopy_linux_installer/releases)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/wieluk/psychopy_linux_installer/scheduled_workflow.yaml?branch=main)](https://github.com/wieluk/psychopy_linux_installer/actions)
![GitHub file size in bytes](https://img.shields.io/github/size/wieluk/psychopy_linux_installer/psychopy_linux_installer?branch=main&label=installer%20size)
[![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/wieluk/psychopy_linux_installer/psychopy_linux_installer)](https://tooomm.github.io/github-release-stats/?username=wieluk&repository=psychopy_linux_installer)

---

This script automates the installation of [PsychoPy](https://www.psychopy.org/) on a wide range of Linux distributions, handling all dependencies and environment setup for you.

## Table of Contents

1. [Supported and Tested Distributions](#supported-and-tested-distributions)
2. [Usage](#usage)
3. [Options](#options)
4. [Examples](#examples)
5. [How the Installer Works](#how-the-installer-works)
6. [Post-Installation](#post-installation)
7. [Uninstalling PsychoPy](#uninstalling-psychopy)
8. [Troubleshooting](#troubleshooting)
9. [Contributing & Support](#contributing--support)
10. [Performance Data](test/performance_data/README.md)

## Supported and Tested Distributions

The installer has been tested and confirmed to work on the following Linux distributions:

- **Ubuntu:** 24.04, 22.04, 20.04
- **Pop!_OS:** 22.04
- **Debian:** 12, 11
- **Fedora:** 41, 40, 39
- **Rocky Linux:** 9
- **CentOS:** 9
- **Linux Mint:** 22
- **openSUSE:** 15
- **Manjaro:** 25

While these distributions are tested, the script is designed to be compatible with other Linux distributions as well.

## Usage

Install `curl` with your package manager if it is not already installed.

### Option 1: One-line Install

Run the installer directly without saving it to disk:

- **GUI Mode** (requires `curl` and `zenity`):

  ```bash
  bash <(curl -LsSf https://github.com/wieluk/psychopy_linux_installer/releases/latest/download/psychopy_linux_installer) --gui
  ```

- **Command-Line Mode**:

  ```bash
  bash <(curl -LsSf https://github.com/wieluk/psychopy_linux_installer/releases/latest/download/psychopy_linux_installer)
  ```

### Option 2: Download Script for Reuse

1. **Download the installer script:**

   ```bash
   curl -LOsSf https://github.com/wieluk/psychopy_linux_installer/releases/latest/download/psychopy_linux_installer
   ```

2. **Make it executable:**

   ```bash
   chmod +x psychopy_linux_installer
   ```

3. **Run the installer:**

   - **GUI Mode** (requires `curl` and `zenity`):

     ```bash
     ./psychopy_linux_installer --gui
     ```

   - **Command-Line Mode**:

     ```bash
     ./psychopy_linux_installer
     ```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--psychopy-version=VERSION` | Specify the PsychoPy version to install (e.g. `2024.2.4`, `latest`, or `git`). | `latest` |
| `--python-version=[3.8.x\|3.9.x\|3.10.x]` | Choose the Python version for the PsychoPy environment. Patch version is optional. | `3.10` |
| `--wxpython-version=VERSION` | Specify the wxPython version to install (e.g. `4.2.3`). | `4.2.3` |
| `--build-wxpython` | Force building wxPython from source instead of downloading prebuilt wheels, even if wheels are available. | *false* |
| `--wxpython-wheel-index=URL` | Provide a custom URL for wxPython wheels. Useful for rolling distributions (e.g., Arch) or distributions that can use wheels built for another compatible system (e.g., Ubuntu-based). Example: `--wxpython-wheel-index=https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ubuntu-24.04/` | *(none)* |
| `--install-dir=DIR` | Set the installation directory for PsychoPy. | `/opt/psychopy` |
| `--target-users=USER1,USER2,...\|*` | Comma-separated users to install for, or '*' for all real users. Adds users to psychopy group and creates symlink/shortcuts | *current user* |
| `--venv-name=NAME` | Set a custom name for the virtual environment folder. | `PsychoPy-${PSYCHOPY_VERSION}-Python${PYTHON_VERSION}` |
| `--additional-packages=PKG,PKG,…` | List extra pip packages to install (comma-separated, supports `package==version`). Example: `--additional-packages=psychopy_bids,seedir,psychopy-crs==0.0.2` | *(none)* |
| `--requirements-file=FILE` | Install all pip packages listed in the given requirements file into the PsychoPy environment. | (none) |
| `--sudo-mode=[ask\|auto\|error\|continue\|force]` | Control how `sudo` is used for system commands:<br>**ask**: Prompt each time sudo is needed.<br>**auto**: Use sudo automatically when required.<br>**error**: Exit if sudo is needed.<br>**continue**: Skip commands needing sudo.<br>**force**: Always use sudo, even if not strictly necessary. | `ask` |
| `--non-interactive` | Run unattended; sets `--sudo-mode=auto` unless specified. | *false* |
| `--disable-shortcut` | Do not create a desktop shortcut for PsychoPy. | *false* |
| `--disable-path` | Do not create a symlink in `/usr/local/bin` or `~/.local/bin`. | *false* |
| `--remove-psychopy-settings` | Delete existing PsychoPy user settings at `~/.psychopy3` during installation. | *false* |
| `--no-fonts` | Skip installation of additional font packages. | *false* |
| `--uninstall-build-packages` | Remove build packages after installation. **Warning**: Setting this to `true` may cause non-admin installations to fail after this main installation. | *false* |
| `--gui` | Launch the graphical installer (ignores other command-line options). | *false* |
| `-f`, `--force-overwrite` | Overwrite the target install folder if it already exists. | *false* |
| `-v`, `--verbose` | Show detailed progress messages in the terminal. | *false* |
| `--version` | Print the installer script version and exit. | *(n/a)* |
| `-h`, `--help` | Show usage information and exit. | *(n/a)* |

**Note:**

- Non-Admin Installation: The `--sudo-mode=continue --install-dir=~/psychopy` option enables non-admin users to upgrade or reinstall if the packages are already installed. This option assumes an administrator has previously run the installation.
- Version Selection: The `--psychopy-version` and `--wxpython-version` options accept specific versions from [PyPI](https://pypi.org), as well as `latest` or `git`. Note that `git` versions may be unstable and are generally not recommended.

## Examples

```bash
bash <(curl -LsSf https://github.com/wieluk/psychopy_linux_installer/releases/latest/download/psychopy_linux_installer) --psychopy-version=2024.2.4 --python-version=3.10 --install-dir=/home/ubuntu/psychopy --venv-name=custom-psychopy --additional-packages=psychopy_bids,seedir,psychopy-crs==0.0.2 --sudo-mode=auto
```

```bash
./psychopy_linux_installer --psychopy-version=2024.2.4 --python-version=3.10 --install-dir=/home/ubuntu/psychopy --venv-name=custom-psychopy --additional-packages=psychopy_bids,seedir,psychopy-crs==0.0.2 --sudo-mode=auto
```

## How the Installer Works

- Detects your Linux distribution and package manager (supports apt, yum, dnf, pacman, and zypper).
- Installs all necessary system dependencies for PsychoPy and wxPython.
- Installs [uv](https://docs.astral.sh/uv/) (a fast Python package manager) and uses it to install the specified Python version (3.8, 3.9, or 3.10).
- Sets up the PsychoPy installation directory at `${INSTALL_DIR}/PsychoPy-${PSYCHOPY_VERSION}-Python${PYTHON_VERSION}` (default: `/opt/psychopy`). You can customize this with `--install-dir` and `--venv-name`.
- Creates a virtual environment and installs wxPython (downloads prebuilt wheels, tries GitHub releases, or builds from source if needed).
- Upgrades pip and required Python packages, then installs the specified PsychoPy version.
- Adds user to `psychopy` group and sets security limits.
- Generates a startup wrapper script (`start_psychopy`) with uninstaller (--unistall).
- Optionally creates a desktop shortcut and a symbolic link in `/usr/local/bin/` or `~/local/bin`.
- Logs all actions to a file (initially in `/tmp`, then moved to the install directory). Use `--verbose` for detailed terminal output.

**Notes:**

- If prebuilt wxPython wheels are unavailable for your distribution, the script will attempt to build from source.
- Building wxPython from source may take significant time and require extra disk space (ensure `/tmp` is large enough).

## Post-Installation

After installation, desktop icons for PsychoPy will be created automatically, and the application will be added to your system's PATH as:

`PsychoPy-${PSYCHOPY_VERSION}-Python${PYTHON_VERSION}` or `${VENV_NAME}`

You can also launch PsychoPy directly using the absolute path:

`${PSYCHOPY_DIR}/start_psychopy`

Please reboot to apply security limits.

**Note:**
All commands, along with the installed versions and set paths, will be displayed at the end of the script.

## Uninstalling PsychoPy

To uninstall PsychoPy using the automated uninstaller, run the `start_psychopy` wrapper script with the `--uninstall` flag.

You can do this in two ways:

- **Using the absolute path (default install directory and venv name):**

  ```bash
  /opt/psychopy/PsychoPy-${PSYCHOPY_VERSION}-Python${PYTHON_VERSION}/start_psychopy --uninstall
  ```

  *(If you used a custom `--install-dir` and/or `--venv-name`, adjust the path accordingly.)*

- **If the PsychoPy wrapper is in your system PATH (symlinked as VENV_NAME):**

  ```bash
  ${VENV_NAME} --uninstall
  ```

  *(By default, `${VENV_NAME}` is `PsychoPy-${PSYCHOPY_VERSION}-Python${PYTHON_VERSION}` unless you set a custom name.)*

During uninstallation, you may be prompted to remove additional files and settings, such as:

- `/etc/security/limits.d/99-psychopylimits.conf`
- the `psychopy` group
- user settings at `~/.psychopy3`
- the `uv` binary and related data
- python versions installed by `uv`
- installed packages that have been added by psychopy_linux_installer

If you have other PsychoPy environments installed on your system, it is recommended to answer **"n"** to these prompts to avoid affecting other installations.

## Troubleshooting

- Ensure your package manager is working and not locked by another process.
- If prebuilt wheels fail, use `--build-wxpython` to build from source.
- Make sure `/tmp` has enough space when building wxPython.
- Review the log file (path shown in the terminal) for details on errors.
- Before opening a new issue, search [existing GitHub issues](https://github.com/wieluk/psychopy_linux_installer/issues?q=is%3Aissue) to see if your problem is already reported or resolved.

## Contributing & Support

- Contributions, bug reports, and feature requests are welcome. Please fork the repository and submit a pull request.
- For help or to report issues, use the [GitHub issue tracker](https://github.com/wieluk/psychopy_linux_installer/issues) and include the relevant log file.
- For general PsychoPy questions, visit the [PsychoPy forums](https://discourse.psychopy.org/) or the [PsychoPy GitHub repository](https://github.com/psychopy/psychopy).

---
