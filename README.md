# PsychoPy Installation Script for Linux

This script facilitates the installation of [PsychoPy](https://www.psychopy.org/) on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04, (18.04)
- Pop!_OS 22.04
- Debian 12, (11)
- CentOS 9

Additional distributions may be tested and supported in the future. All tests are conducted on Virtual Machines only.

**Note:**

- Ubuntu 18.04 does not work with the default (latest) PsychoPy version. It fails to install pyqt6. Use PsychoPy version 2023.2.3 or lower.
- Debian 11 requires an extra manual command after installation: `export QT_QPA_PLATFORM=xcb`.

## Important Information

- PsychoPy recommends using Python 3.8 or 3.10. Python 3.8 is generally more reliable.
- The specified/default Python version is installed as `altinstall` if not present.
- A directory is created in the specified directory (default: `$HOME`):
  `{install_dir}/psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`.
- Building Python and wxPython might take some time.

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

- `--python_version=VERSION` : Specify the Python version to install (default: `3.8.16`).
- `--psychopy_version=VERSION` : Specify the PsychoPy version to install (default: `latest`); use `--psychopy_version=git` for the latest GitHub version.
- `--install_dir=DIR` : Specify the installation directory (default: `$HOME`); use absolute paths without a trailing `/`. Do not use `~/`; use `/home/{user}` instead.
- `--bids_version=VERSION` : Specify the PsychoPy-BIDS version to install; skip if not set
- `-f`, `--force` : Force overwrite of the existing installation directory.
- `-h`, `--help` : Show help message.

## Examples

- `./psychopy_linux_installer.sh` (all default)
- `./psychopy_linux_installer.sh --python_version=3.8.16 --psychopy_version=2024.1.4 --install_dir=/home/user1 --bids_version=git`

## Script Details

The script performs the following steps:

- Detects the package manager (supports apt, yum, dnf, and pacman).
- Installs necessary dependencies.
- Checks if the specified Python version exists and downloads it if necessary.
- Determines the PsychoPy version to install:
- If latest, it fetches the latest version from PyPI.
- If git, it installs PsychoPy from the latest GitHub repository.
- Creates a directory in the specified location for PsychoPy.
- Downloads and installs the specified Python version as `altinstall`.
- Creates and activates a virtual environment for PsychoPy.
- Upgrades pip and setuptools, and installs wxPython.
- Installs PsychoPy.
- Adds the current user to a `psychopy` group and sets security limits.
- Creates a symbolic link to the PsychoPy executable in `.bin`.

## Post-Installation

To start PsychoPy, use the absolute path:

`"${PSYCHOPY_DIR}/bin/psychopy"`

Alternatively, if adding to path worked, use:

`psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`

(Both commands will be shown with actual versions at the end of the script).

## Notes

- Additional packages may be required for extended features.
- Some installed dependencies might not be necessary; further testing is needed to identify these.
- Only very basic tests of actual PsychoPy components were performed.
- Distributions with the pacman package manager have not been tested yet.
- [PsychoPy Versions](https://pypi.org/project/psychopy/#history)
- [PsychoPy Github](https://github.com/psychopy/psychopy)
- [Python Versions](https://www.python.org/ftp/python)
- [PsychoPy_bids Versions](https://pypi.org/project/psychopy_bids/0.1.1/#history)
- [PsychoPy_bids GitLab](https://gitlab.com/psygraz/psychopy-bids)

## Automatic Github Action Test Results

<!-- BEGIN INSTALLATION_RESULTS -->
Report generated on 2024-07-16

| OS | Python Version | PsychoPy Version | BIDS Version | Status |
|---|---|---|---|---|
| ubuntu-20.04 | 3.10.14 | 2023.2.3 |  | ❌ |
| ubuntu-20.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-20.04 | 3.10.14 | 2023.2.3 | git | ❌ |
| ubuntu-20.04 | 3.10.14 | 2024.1.3 |  | ❌ |
| ubuntu-20.04 | 3.10.14 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-20.04 | 3.10.14 | 2024.1.3 | git | ❌ |
| ubuntu-20.04 | 3.10.14 | git |  | ✅ |
| ubuntu-20.04 | 3.10.14 | git | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.10.14 | git | git | ✅ |
| ubuntu-20.04 | 3.10.14 | latest |  | ❌ |
| ubuntu-20.04 | 3.10.14 | latest | 2023.2.0 | ❌ |
| ubuntu-20.04 | 3.10.14 | latest | git | ❌ |
| ubuntu-20.04 | 3.8.16 | 2023.2.3 |  | ✅ |
| ubuntu-20.04 | 3.8.16 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.8.16 | 2023.2.3 | git | ✅ |
| ubuntu-20.04 | 3.8.16 | 2024.1.3 |  | ✅ |
| ubuntu-20.04 | 3.8.16 | 2024.1.3 | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.8.16 | 2024.1.3 | git | ✅ |
| ubuntu-20.04 | 3.8.16 | git |  | ✅ |
| ubuntu-20.04 | 3.8.16 | git | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.8.16 | git | git | ✅ |
| ubuntu-20.04 | 3.8.16 | latest |  | ✅ |
| ubuntu-20.04 | 3.8.16 | latest | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.8.16 | latest | git | ✅ |
| ubuntu-20.04 | 3.9.19 | 2023.2.3 |  | ❌ |
| ubuntu-20.04 | 3.9.19 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-20.04 | 3.9.19 | 2023.2.3 | git | ❌ |
| ubuntu-20.04 | 3.9.19 | 2024.1.3 |  | ❌ |
| ubuntu-20.04 | 3.9.19 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-20.04 | 3.9.19 | 2024.1.3 | git | ❌ |
| ubuntu-20.04 | 3.9.19 | git |  | ✅ |
| ubuntu-20.04 | 3.9.19 | git | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.9.19 | git | git | ✅ |
| ubuntu-20.04 | 3.9.19 | latest |  | ❌ |
| ubuntu-20.04 | 3.9.19 | latest | 2023.2.0 | ❌ |
| ubuntu-20.04 | 3.9.19 | latest | git | ❌ |
| ubuntu-22.04 | 3.10.14 | 2023.2.3 |  | ❌ |
| ubuntu-22.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.10.14 | 2023.2.3 | git | ❌ |
| ubuntu-22.04 | 3.10.14 | 2024.1.3 |  | ❌ |
| ubuntu-22.04 | 3.10.14 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.10.14 | 2024.1.3 | git | ❌ |
| ubuntu-22.04 | 3.10.14 | git |  | ✅ |
| ubuntu-22.04 | 3.10.14 | git | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.10.14 | git | git | ✅ |
| ubuntu-22.04 | 3.10.14 | latest |  | ❌ |
| ubuntu-22.04 | 3.10.14 | latest | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.10.14 | latest | git | ❌ |
| ubuntu-22.04 | 3.8.16 | 2023.2.3 |  | ✅ |
| ubuntu-22.04 | 3.8.16 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.8.16 | 2023.2.3 | git | ✅ |
| ubuntu-22.04 | 3.8.16 | 2024.1.3 |  | ✅ |
| ubuntu-22.04 | 3.8.16 | 2024.1.3 | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.8.16 | 2024.1.3 | git | ✅ |
| ubuntu-22.04 | 3.8.16 | git |  | ✅ |
| ubuntu-22.04 | 3.8.16 | git | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.8.16 | git | git | ✅ |
| ubuntu-22.04 | 3.8.16 | latest |  | ✅ |
| ubuntu-22.04 | 3.8.16 | latest | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.8.16 | latest | git | ✅ |
| ubuntu-22.04 | 3.9.19 | 2023.2.3 |  | ❌ |
| ubuntu-22.04 | 3.9.19 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.9.19 | 2023.2.3 | git | ❌ |
| ubuntu-22.04 | 3.9.19 | 2024.1.3 |  | ❌ |
| ubuntu-22.04 | 3.9.19 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.9.19 | 2024.1.3 | git | ❌ |
| ubuntu-22.04 | 3.9.19 | git |  | ✅ |
| ubuntu-22.04 | 3.9.19 | git | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.9.19 | git | git | ✅ |
| ubuntu-22.04 | 3.9.19 | latest |  | ❌ |
| ubuntu-22.04 | 3.9.19 | latest | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.9.19 | latest | git | ❌ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 |  | ❌ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | git | ❌ |
| ubuntu-24.04 | 3.10.14 | 2024.1.3 |  | ❌ |
| ubuntu-24.04 | 3.10.14 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.10.14 | 2024.1.3 | git | ❌ |
| ubuntu-24.04 | 3.10.14 | git |  | ✅ |
| ubuntu-24.04 | 3.10.14 | git | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | git | git | ✅ |
| ubuntu-24.04 | 3.10.14 | latest |  | ❌ |
| ubuntu-24.04 | 3.10.14 | latest | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.10.14 | latest | git | ❌ |
| ubuntu-24.04 | 3.8.16 | 2023.2.3 |  | ✅ |
| ubuntu-24.04 | 3.8.16 | 2023.2.3 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.16 | 2023.2.3 | git | ✅ |
| ubuntu-24.04 | 3.8.16 | 2024.1.3 |  | ✅ |
| ubuntu-24.04 | 3.8.16 | 2024.1.3 | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.16 | 2024.1.3 | git | ✅ |
| ubuntu-24.04 | 3.8.16 | git |  | ✅ |
| ubuntu-24.04 | 3.8.16 | git | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.16 | git | git | ✅ |
| ubuntu-24.04 | 3.8.16 | latest |  | ✅ |
| ubuntu-24.04 | 3.8.16 | latest | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.8.16 | latest | git | ✅ |
| ubuntu-24.04 | 3.9.19 | 2023.2.3 |  | ❌ |
| ubuntu-24.04 | 3.9.19 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.9.19 | 2023.2.3 | git | ❌ |
| ubuntu-24.04 | 3.9.19 | 2024.1.3 |  | ❌ |
| ubuntu-24.04 | 3.9.19 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.9.19 | 2024.1.3 | git | ❌ |
| ubuntu-24.04 | 3.9.19 | git |  | ✅ |
| ubuntu-24.04 | 3.9.19 | git | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | git | git | ✅ |
| ubuntu-24.04 | 3.9.19 | latest |  | ❌ |
| ubuntu-24.04 | 3.9.19 | latest | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.9.19 | latest | git | ❌ |
<!-- END INSTALLATION_RESULTS -->
