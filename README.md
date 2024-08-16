# PsychoPy Installation Script for Linux

This script facilitates the installation of [PsychoPy](https://www.psychopy.org/) on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04, 18.04
- Pop!_OS 22.04
- Debian 12, 11
- Fedora 39
- Rocky Linux 9
- CentOS 9

Additional distributions may be working.


## Important Information

- PsychoPy is compatible with Python versions 3.8, 3.9, and 3.10. PsychoPy seems to be moving towards Python3.10.
- The specified/default(3.10.14) Python version is installed as `altinstall` if not present.
- A directory is created in the specified directory (default: `$HOME`):
  `{install_dir}/psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`.
- The script first attempts to download a pre-packaged Python .tar.gz file from [Nextcloud](https://cloud.uni-graz.at/s/o4tnQgN6gjDs3CK). If a suitable version isn't found, it will download from python.org and build it from source.
- For wxPython, the script tries to download from their [official site](https://extras.wxpython.org/wxPython4/extras/linux/gtk3/). If this fails, it falls back to [Nextcloud](https://cloud.uni-graz.at/s/YtX33kbasHMZdgs) or, if necessary, builds wxPython from source. Building Python and wxPython may take 1-2 hours.
- The script provides minimal output by default. Use the --verbose option for detailed logging.

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

- `--python_version=VERSION` : Specify the [Python Version](https://www.python.org/ftp/python) to install (default: `3.10.14`).
- `--psychopy_version=VERSION` : Specify the [PsychoPy Version](https://pypi.org/project/psychopy/#history) to install (default: `2024.1.1`); use `latest` for the latest pypi version; use `git` for the latest GitHub version.
- `--install_dir=DIR` : Specify the installation directory (default: `$HOME`); use absolute paths without a trailing `/`. Do not use `~/`; use `/home/{user}` instead.
- `--bids_version=VERSION` : Specify the [PsychoPy_BIDS version](https://pypi.org/project/psychopy_bids/#history) to install (default: latest);  use None to skip bids installation
- `--build` : Build Python and wxPython from source instead of downloading wheel/binaries; Options are: `[python|wxpython|both]`. Use `both` if something does not work. It might take 1-2 hours."
- `-f`, `--force` : Force overwrite of the existing installation directory.
- `-v`, `--verbose` : Enable verbose output.
- `-d`, `--disable-shortcut` : Disable desktop shortcut creation.
- `-h`, `--help` : Show help message.

**Note:**
The default version for `--psychopy_version` is set to `2024.1.4` Because new releases for Linux often introduce bugs that require manual fixes. For example `2024.2.1` has problems with opening the GUI when not installing a earlier version first.

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
After installation, desktop icons for PsychoPy will be created automatically, and the application will be added to your system's PATH as:

`psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`

Refreshing your system's PATH may be necessary.



You can also launch PsychoPy directly using the absolute path:

`${PSYCHOPY_DIR}/bin/psychopy`


**Note:** 
All commands, along with the installed versions and set paths, as well as the command to refresh your system's PATH, will be displayed at the end of the script.

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

## Automated Installation and Test Results for OS, Python, and PsychoPy Version Combinations

<!-- BEGIN INSTALLATION_RESULTS -->
### Report generated on 2024-08-16
### [Link to run results](https://github.com/wieluk/psychopy_linux_installer/actions/runs/10423695199)

| OS | Python Version | PsychoPy Version | BIDS Version | Status |
|---|---|---|---|---|
| debian-12 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| debian-12 | 3.10.14 | 2023.2.3 | None | ✅ |
| debian-12 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| debian-12 | 3.10.14 | 2024.1.4 | None | ✅ |
| debian-12 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| debian-12 | 3.10.14 | 2024.2.1 | None | ✅ |
| debian-12 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| debian-12 | 3.8.19 | 2023.2.3 | None | ✅ |
| debian-12 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| debian-12 | 3.8.19 | 2024.1.4 | None | ✅ |
| debian-12 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| debian-12 | 3.8.19 | 2024.2.1 | None | ✅ |
| debian-12 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| debian-12 | 3.9.19 | 2023.2.3 | None | ✅ |
| debian-12 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| debian-12 | 3.9.19 | 2024.1.4 | None | ✅ |
| debian-12 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| debian-12 | 3.9.19 | 2024.2.1 | None | ✅ |
| fedora-39 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| fedora-39 | 3.10.14 | 2023.2.3 | None | ✅ |
| fedora-39 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| fedora-39 | 3.10.14 | 2024.1.4 | None | ✅ |
| fedora-39 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| fedora-39 | 3.10.14 | 2024.2.1 | None | ✅ |
| fedora-39 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| fedora-39 | 3.8.19 | 2023.2.3 | None | ✅ |
| fedora-39 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| fedora-39 | 3.8.19 | 2024.1.4 | None | ✅ |
| fedora-39 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| fedora-39 | 3.8.19 | 2024.2.1 | None | ✅ |
| fedora-39 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| fedora-39 | 3.9.19 | 2023.2.3 | None | ✅ |
| fedora-39 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| fedora-39 | 3.9.19 | 2024.1.4 | None | ✅ |
| fedora-39 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| fedora-39 | 3.9.19 | 2024.2.1 | None | ✅ |
| pop-22.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| pop-22.04 | 3.10.14 | 2023.2.3 | None | ✅ |
| pop-22.04 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| pop-22.04 | 3.10.14 | 2024.1.4 | None | ✅ |
| pop-22.04 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| pop-22.04 | 3.10.14 | 2024.2.1 | None | ✅ |
| pop-22.04 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| pop-22.04 | 3.8.19 | 2023.2.3 | None | ✅ |
| pop-22.04 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| pop-22.04 | 3.8.19 | 2024.1.4 | None | ✅ |
| pop-22.04 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| pop-22.04 | 3.8.19 | 2024.2.1 | None | ✅ |
| pop-22.04 | 3.9.19 | 2023.2.3 | 2023.2.0 | ❌ |
| pop-22.04 | 3.9.19 | 2023.2.3 | None | ✅ |
| pop-22.04 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| pop-22.04 | 3.9.19 | 2024.1.4 | None | ✅ |
| pop-22.04 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| pop-22.04 | 3.9.19 | 2024.2.1 | None | ✅ |
| rocky-9.4 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.10.14 | 2023.2.3 | None | ✅ |
| rocky-9.4 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.10.14 | 2024.1.4 | None | ✅ |
| rocky-9.4 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.10.14 | 2024.2.1 | None | ✅ |
| rocky-9.4 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.8.19 | 2023.2.3 | None | ✅ |
| rocky-9.4 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.8.19 | 2024.1.4 | None | ✅ |
| rocky-9.4 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.8.19 | 2024.2.1 | None | ✅ |
| rocky-9.4 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.9.19 | 2023.2.3 | None | ✅ |
| rocky-9.4 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.9.19 | 2024.1.4 | None | ✅ |
| rocky-9.4 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| rocky-9.4 | 3.9.19 | 2024.2.1 | None | ✅ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | None | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.1.4 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.1.4 | None | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.2.1 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | 2024.2.1 | None | ✅ |
| ubuntu-24.04 | 3.8.19 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.19 | 2023.2.3 | None | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.1.4 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.1.4 | None | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.2.1 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.19 | 2024.2.1 | None | ✅ |
| ubuntu-24.04 | 3.9.19 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | 2023.2.3 | None | ❌ |
| ubuntu-24.04 | 3.9.19 | 2024.1.4 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | 2024.1.4 | None | ✅ |
| ubuntu-24.04 | 3.9.19 | 2024.2.1 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | 2024.2.1 | None | ✅ |
<!-- END INSTALLATION_RESULTS -->

## Built Python and wxPython Versions Available for Download

[wxPython on Nextcloud](https://cloud.uni-graz.at/s/YtX33kbasHMZdgs)

[Python on Nextcloud](https://cloud.uni-graz.at/s/o4tnQgN6gjDs3CK)
<!-- BEGIN PRECOMPILED_VERSIONS -->
### Report generated on 2024-08-16

| OS | Python Version | WxPython Version |
|---|---|---|
| centos-9 | 3.10.14 | 4.2.1 |
| centos-9 | 3.8.19 | 4.2.1 |
| centos-9 | 3.9.19 | 4.2.1 |
| debian-11 | 3.10.14 | 4.2.1 |
| debian-11 | 3.8.19 | 4.2.1 |
| debian-11 | 3.9.19 | 4.2.1 |
| debian-12 | 3.10.14 | 4.2.1 |
| debian-12 | 3.8.19 | 4.2.1 |
| debian-12 | 3.9.19 | 4.2.1 |
| fedora-39 | 3.10.14 | 4.2.1 |
| fedora-39 | 3.8.19 | 4.2.1 |
| fedora-39 | 3.9.19 | 4.2.1 |
| pop-22.04 | 3.10.14 | 4.2.1 |
| pop-22.04 | 3.8.19 | 4.2.1 |
| pop-22.04 | 3.9.19 | 4.2.1 |
| rocky-9.4 | 3.10.14 | 4.2.1 |
| rocky-9.4 | 3.8.19 | 4.2.1 |
| rocky-9.4 | 3.9.19 | 4.2.1 |
| ubuntu-20.04 | 3.10.14 | 4.2.1 |
| ubuntu-20.04 | 3.8.19 | 4.2.1 |
| ubuntu-20.04 | 3.9.19 | 4.2.1 |
| ubuntu-22.04 | 3.10.14 | 4.2.1 |
| ubuntu-22.04 | 3.8.19 | 4.2.1 |
| ubuntu-22.04 | 3.9.19 | 4.2.1 |
| ubuntu-24.04 | 3.10.14 | 4.2.1 |
| ubuntu-24.04 | 3.8.19 | 4.2.1 |
| ubuntu-24.04 | 3.9.19 | 4.2.1 |
<!-- END PRECOMPILED_VERSIONS -->