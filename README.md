# PsychoPy Installation Script for Linux

This script facilitates the installation of [PsychoPy](https://www.psychopy.org/) on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04, (18.04)
- Pop!_OS 22.04
- Debian 12, (11)
- Fedora 39
- (CentOS 9)

Additional distributions may be tested and supported in the future. All tests are conducted on Virtual Machines only.

**Note:**

- Ubuntu 18.04, Debian 11 and CentOS 9 do not work with the default (2024.1.4) PsychoPy version. They fail to install pyqt6. Use PsychoPy version 2023.2.3 or lower. Or fix dependency errors manually (and please tell me how to fix them).

## Important Information

- PsychoPy recommends using Python 3.8 or 3.10. Python 3.8 is generally more reliable.
- The specified/default Python version is installed as `altinstall` if not present.
- A directory is created in the specified directory (default: `$HOME`):
  `{install_dir}/psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`.
- The script attempts to download a pre-made Python .tar.gz file from my [Nextcloud](https://cloud.uni-graz.at/s/o4tnQgN6gjDs3CK). If it fails to find a matching version, it will download from python.org and build from source.
- The script also tries to find a wxPython version from their [website](https://extras.wxpython.org/wxPython4/extras/linux/gtk3/). If this fails, it falls back to my [Nextcloud](https://cloud.uni-graz.at/s/YtX33kbasHMZdgs). If this also fails, wxPython is built from source.
- Building Python and wxPython might take some time (1-2 hours).
- The script output is minimal by default. Use the --verbose option to view detailed output.
- For most distros starting PsychoPy the first time is sometimes buggy. Just restart it or use the --coder, --builder option when starting.

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
- `--psychopy_version=VERSION` : Specify the [PsychoPy Version](https://pypi.org/project/psychopy/#history) to install (default: `2024.1.4`); use `latest` for latest pypi version; use `git` for the latest GitHub version.
- `--install_dir=DIR` : Specify the installation directory (default: `$HOME`); use absolute paths without a trailing `/`. Do not use `~/`; use `/home/{user}` instead.
- `--bids_version=VERSION` : Specify the [PsychoPy_BIDS version](https://pypi.org/project/psychopy_bids/#history) to install; skip if not set
- `--build` : Build Python and wxPython from source instead of downloading wheel/binaries; Options are: `[python|wxpython|both]`. Use `both` if something does not work. It might take 1-2 hours."
- `-f`, `--force` : Force overwrite of the existing installation directory.
- `-v`, `--verbose` : Enable verbose output.
- `-h`, `--help` : Show help message.

**Note:**
The default version for `--psychopy_version` is no longer set to the latest version because new releases often introduce bugs for Linux that require manual fixes. For example, while writing this, the latest version is 2024.2.0, which does not start successfully in my tests.

## Examples

- `./psychopy_linux_installer.sh` (all default)
- `./psychopy_linux_installer.sh --python_version=3.8.16 --psychopy_version=2024.1.3 --install_dir=/home/user1 --bids_version=git --build=python -v -f`

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

## Post-Installation

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

### Dependencies

- Identify and remove unnecessary packages for specific platforms.
- Consider splitting package installations for each distribution.
- Test on Pacman-based distributions.

### Tests

- Evaluate BIDS compatibility.
- Assess extended PsychoPy features.
- Conduct tests on a physical machine.
- Test with connected hardware components.

### Additional Tasks

- Add self-hosted action runners for Debian, Fedora, and CentOS.

## Links

- [PsychoPy Github](https://github.com/psychopy/psychopy)
- [PsychoPy_bids GitLab](https://gitlab.com/psygraz/psychopy-bids)

## Automatic Github Action Test Results

<!-- BEGIN INSTALLATION_RESULTS -->
# Report generated on 2024-07-25

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
| ubuntu-20.04 | 3.10.14 | latest |  | ✅ |
| ubuntu-20.04 | 3.10.14 | latest | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.10.14 | latest | git | ✅ |
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
| ubuntu-20.04 | 3.9.19 | latest |  | ✅ |
| ubuntu-20.04 | 3.9.19 | latest | 2023.2.0 | ✅ |
| ubuntu-20.04 | 3.9.19 | latest | git | ✅ |
| ubuntu-22.04 | 3.10.14 | 2023.2.3 |  | ❌ |
| ubuntu-22.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.10.14 | 2023.2.3 | git | ❌ |
| ubuntu-22.04 | 3.10.14 | 2024.1.3 |  | ❌ |
| ubuntu-22.04 | 3.10.14 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-22.04 | 3.10.14 | 2024.1.3 | git | ❌ |
| ubuntu-22.04 | 3.10.14 | git |  | ✅ |
| ubuntu-22.04 | 3.10.14 | git | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.10.14 | git | git | ✅ |
| ubuntu-22.04 | 3.10.14 | latest |  | ✅ |
| ubuntu-22.04 | 3.10.14 | latest | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.10.14 | latest | git | ✅ |
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
| ubuntu-22.04 | 3.9.19 | latest |  | ✅ |
| ubuntu-22.04 | 3.9.19 | latest | 2023.2.0 | ✅ |
| ubuntu-22.04 | 3.9.19 | latest | git | ✅ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 |  | ❌ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.10.14 | 2023.2.3 | git | ❌ |
| ubuntu-24.04 | 3.10.14 | 2024.1.3 |  | ❌ |
| ubuntu-24.04 | 3.10.14 | 2024.1.3 | 2023.2.0 | ❌ |
| ubuntu-24.04 | 3.10.14 | 2024.1.3 | git | ❌ |
| ubuntu-24.04 | 3.10.14 | git |  | ✅ |
| ubuntu-24.04 | 3.10.14 | git | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | git | git | ✅ |
| ubuntu-24.04 | 3.10.14 | latest |  | ✅ |
| ubuntu-24.04 | 3.10.14 | latest | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.10.14 | latest | git | ✅ |
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
| ubuntu-24.04 | 3.9.19 | latest |  | ✅ |
| ubuntu-24.04 | 3.9.19 | latest | 2023.2.0 | ✅ |
| ubuntu-24.04 | 3.9.19 | latest | git | ✅ |
<!-- END INSTALLATION_RESULTS -->
