# PsychoPy Installation Script for Linux

This script facilitates the installation of [PsychoPy](https://www.psychopy.org/) on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04, (18.04)
- Pop!_OS 22.04
- Debian 12, (11)
- Fedora 39
- Rocky Linux 9
- (CentOS 9)

Additional distributions may be working. These are the one I tested. All tests are conducted on Virtual Machines only.

**Note:**

- Ubuntu 18.04, Debian 11 and CentOS 9 do not work with the default (2024.1.4) PsychoPy version. They fail to install pyqt6. Use PsychoPy version 2023.2.3 or lower. Or fix dependency errors manually (and please tell me how to fix them).

## Important Information

- PsychoPy requires Python >= 3.8 or <3.11.
- The specified/default(3.8.16) Python version is installed as `altinstall` if not present.
- A directory is created in the specified directory (default: `$HOME`):
  `{install_dir}/psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`.
- The script attempts to download a pre-made Python .tar.gz file from my [Nextcloud](https://cloud.uni-graz.at/s/o4tnQgN6gjDs3CK). If it fails to find a matching version, it will download from python.org and build from source.
- The script also tries to find a wxPython version from their [website](https://extras.wxpython.org/wxPython4/extras/linux/gtk3/). If this fails, it falls back to my [Nextcloud](https://cloud.uni-graz.at/s/YtX33kbasHMZdgs). If this also fails, wxPython is built from source.
- Building Python and wxPython might take some time (1-2 hours).
- The script output is minimal by default. Use the --verbose option to view detailed output.

## Usage

(Optional) Update and upgrade packages; change `apt-get` to your package manager.

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

Install Git

```bash
sudo apt-get install git -y
```

Clone the repository and allow execution:

```bash
git clone https://github.com/wieluk/psychopy_linux_installer.git
cd psychopy_linux_installer
chmod +x psychopy_linux_installer.sh
```

Execute script; see options below for more information.

```bash
./psychopy_linux_installer.sh
```

## Options

- `--python_version=VERSION` : Specify the [Python Version](https://www.python.org/ftp/python) to install (default: `3.8.16`).
- `--psychopy_version=VERSION` : Specify the [PsychoPy Version](https://pypi.org/project/psychopy/#history) to install (default: `latest`); use `git` for the latest GitHub version.
- `--install_dir=DIR` : Specify the installation directory (default: `$HOME`); use absolute paths without a trailing `/`. Do not use `~/`; use `/home/{user}` instead.
- `--bids_version=VERSION` : Specify the [PsychoPy_BIDS version](https://pypi.org/project/psychopy_bids/#history) to install (default: latest);  use None to skip bids installation
- `--build` : Build Python and wxPython from source instead of downloading wheel/binaries; Options are: `[python|wxpython|both]`. Use `both` if something does not work. It might take 1-2 hours."
- `--non-interactive` : Automatically answer `y` to all prompts"
- `-f`, `--force` : Force overwrite of the existing installation directory.
- `-v`, `--verbose` : Enable verbose output.
- `-d`, `--disable-shortcut` : Disable desktop shortcut creation.
- `-h`, `--help` : Show help message.

**Note:**
The default version for `--psychopy_version` is set to latest. Sometimes new releases introduce bugs for Linux that require manual fixes. 

## Examples

- `./psychopy_linux_installer.sh` (all default)
- `./psychopy_linux_installer.sh --psychopy_version=2024.1.4 --install_dir=/home/user1 --bids_version=git --build=python -v -f`

## Script Details

The script performs the following steps:

- Detects the package manager (supports apt, yum, dnf, and pacman).
- Installs necessary dependencies.
- Creates a directory in the specified location for PsychoPy.
- Checks if the specified Python version exists and downloads it if necessary.
- Downloads and installs the specified Python version as `altinstall`.
- Creates and activates a virtual environment for PsychoPy.
- Determines the PsychoPy version to install:
- If latest, it fetches the latest version from PyPI.
- If git, it installs PsychoPy from the latest GitHub repository.
- Upgrades pip and some pip packages, and
- Installs/builds wxPython.
- Installs PsychoPy.
- Adds the current user to a `psychopy` group and sets security limits.
- Creates a symbolic link to the PsychoPy executable in `.bin`.
- Creates a desktop shortcut by default. 

## Post-Installation

### If you do not want to use the desktop icons or creation fails:

To refresh the path for different shells (.bashrc,.zshrc,config.fish,.cshrc,.tcshrc), use the following command:

`source $CONFIG_FILE`

For default Ubuntu, the command should be:

`source ~/.bashrc`

To start PsychoPy, use:

`psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`

If adding to the path did not work, use the absolute path:

`${PSYCHOPY_DIR}/bin/psychopy`

Note: All commands will be displayed with the actual versions and paths at the end of the script.

## To-Do

### Main

- Refactor bash script, actions and testscripts
- Conduct tests on a physical machine.
- Test with connected hardware components.

### Dependencies

- Identify and remove unnecessary packages for specific platforms.
- Consider splitting package installations for each distribution.
- Test on Pacman-based distributions.


## Links

- [PsychoPy Github](https://github.com/psychopy/psychopy)
- [PsychoPy_bids GitLab](https://gitlab.com/psygraz/psychopy-bids)

## Automatic Github Action Test Results

<!-- BEGIN INSTALLATION_RESULTS -->
# Report generated on 2024-08-08

| OS | Python Version | PsychoPy Version | BIDS Version | Status |
|---|---|---|---|---|
| debian-12 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| debian-12 | 3.10.14 | 2023.2.3 | None | ✅ |
| debian-12 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| debian-12 | 3.10.14 | 2024.1.4 | None | ✅ |
| debian-12 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| debian-12 | 3.10.14 | 2024.2.1 | None | ✅ |
| debian-12 | 3.10.14 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| debian-12 | 3.10.14 | untagged-4387d73b9220e140af9b | None | ✅ |
| debian-12 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| debian-12 | 3.8.19 | 2023.2.3 | None | ✅ |
| debian-12 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| debian-12 | 3.8.19 | 2024.1.4 | None | ✅ |
| debian-12 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| debian-12 | 3.8.19 | 2024.2.1 | None | ✅ |
| debian-12 | 3.8.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| debian-12 | 3.8.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| debian-12 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| debian-12 | 3.9.19 | 2023.2.3 | None | ✅ |
| debian-12 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| debian-12 | 3.9.19 | 2024.1.4 | None | ✅ |
| debian-12 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| debian-12 | 3.9.19 | 2024.2.1 | None | ✅ |
| debian-12 | 3.9.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| debian-12 | 3.9.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| fedora-39 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| fedora-39 | 3.10.14 | 2023.2.3 | None | ✅ |
| fedora-39 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| fedora-39 | 3.10.14 | 2024.1.4 | None | ✅ |
| fedora-39 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| fedora-39 | 3.10.14 | 2024.2.1 | None | ✅ |
| fedora-39 | 3.10.14 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| fedora-39 | 3.10.14 | untagged-4387d73b9220e140af9b | None | ✅ |
| fedora-39 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| fedora-39 | 3.8.19 | 2023.2.3 | None | ✅ |
| fedora-39 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| fedora-39 | 3.8.19 | 2024.1.4 | None | ✅ |
| fedora-39 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| fedora-39 | 3.8.19 | 2024.2.1 | None | ✅ |
| fedora-39 | 3.8.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| fedora-39 | 3.8.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| fedora-39 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| fedora-39 | 3.9.19 | 2023.2.3 | None | ✅ |
| fedora-39 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| fedora-39 | 3.9.19 | 2024.1.4 | None | ✅ |
| fedora-39 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| fedora-39 | 3.9.19 | 2024.2.1 | None | ✅ |
| fedora-39 | 3.9.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| fedora-39 | 3.9.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| pop-22.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| pop-22.04 | 3.10.14 | 2023.2.3 | None | ✅ |
| pop-22.04 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| pop-22.04 | 3.10.14 | 2024.1.4 | None | ❌ |
| pop-22.04 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| pop-22.04 | 3.10.14 | 2024.2.1 | None | ✅ |
| pop-22.04 | 3.10.14 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| pop-22.04 | 3.10.14 | untagged-4387d73b9220e140af9b | None | ✅ |
| pop-22.04 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| pop-22.04 | 3.8.19 | 2023.2.3 | None | ✅ |
| pop-22.04 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| pop-22.04 | 3.8.19 | 2024.1.4 | None | ❌ |
| pop-22.04 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| pop-22.04 | 3.8.19 | 2024.2.1 | None | ✅ |
| pop-22.04 | 3.8.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| pop-22.04 | 3.8.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| pop-22.04 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| pop-22.04 | 3.9.19 | 2023.2.3 | None | ❌ |
| pop-22.04 | 3.9.19 | 2024.1.4 | 2023.2.0 | ❌ |
| pop-22.04 | 3.9.19 | 2024.1.4 | None | ✅ |
| pop-22.04 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| pop-22.04 | 3.9.19 | 2024.2.1 | None | ✅ |
| pop-22.04 | 3.9.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ❌ |
| pop-22.04 | 3.9.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| rocky-9.4 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.10.14 | 2023.2.3 | None | ✅ |
| rocky-9.4 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.10.14 | 2024.1.4 | None | ✅ |
| rocky-9.4 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.10.14 | 2024.2.1 | None | ✅ |
| rocky-9.4 | 3.10.14 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| rocky-9.4 | 3.10.14 | untagged-4387d73b9220e140af9b | None | ✅ |
| rocky-9.4 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.8.19 | 2023.2.3 | None | ✅ |
| rocky-9.4 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.8.19 | 2024.1.4 | None | ✅ |
| rocky-9.4 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.8.19 | 2024.2.1 | None | ✅ |
| rocky-9.4 | 3.8.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| rocky-9.4 | 3.8.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| rocky-9.4 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.9.19 | 2023.2.3 | None | ✅ |
| rocky-9.4 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.9.19 | 2024.1.4 | None | ✅ |
| rocky-9.4 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.9.19 | 2024.2.1 | None | ✅ |
| rocky-9.4 | 3.9.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| rocky-9.4 | 3.9.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | None | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.1.4 | None | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.2.1 | None | ✅ |
| ubuntu-24.04 | 3.10.14 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | untagged-4387d73b9220e140af9b | None | ✅ |
| ubuntu-24.04 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.19 | 2023.2.3 | None | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.1.4 | None | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.2.1 | None | ✅ |
| ubuntu-24.04 | 3.8.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.19 | untagged-4387d73b9220e140af9b | None | ✅ |
| ubuntu-24.04 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | 2023.2.3 | None | ✅ |
| ubuntu-24.04 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | 2024.1.4 | None | ✅ |
| ubuntu-24.04 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | 2024.2.1 | None | ✅ |
| ubuntu-24.04 | 3.9.19 | untagged-4387d73b9220e140af9b | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | untagged-4387d73b9220e140af9b | None | ✅ |
<!-- END INSTALLATION_RESULTS -->
