# PsychoPy Installation Script for Linux

This script facilitates the installation of [PsychoPy](https://www.psychopy.org/) on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04, (18.04)
- Pop!_OS 22.04
- Debian 12, 11
- Fedora 40, 39
- Rocky Linux 9
- CentOS 9

Additional distributions may be working.

**Note:**
Ubuntu-18.04 fails to install PyQt6. You can still use Ubuntu-18 with PsychoPy versions =< 2023.2.3. Earlier versions use PyQt5.

## Important Information

- PsychoPy is compatible with Python versions 3.8, 3.9, and 3.10.
- The specified/default(3.8.19) Python version is installed as `altinstall` if not present.
- A directory is created in the specified directory (default: `$HOME`):
  `{install_dir}/psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`.
- The script first attempts to download a pre-packaged Python .tar.gz file from [Nextcloud](https://cloud.uni-graz.at/s/o4tnQgN6gjDs3CK). If a suitable version isn't found, it will download from python.org and build it from source.
- For wxPython, the script tries to download from their [official site](https://extras.wxpython.org/wxPython4/extras/linux/gtk3/). If this fails, it falls back to [Nextcloud](https://cloud.uni-graz.at/s/YtX33kbasHMZdgs) or, if necessary, builds wxPython from source. If latest wxpython version fails building, it will fallback to version 4.1.1 if no `--wxpython-version` is set. (fixes fedora-40)
- If the downloads fail building Python and wxPython may take 1-2 hours.
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
chmod +x psychopy_linux_installer
```

Execute script; see options below for more information.

```bash
./psychopy_linux_installer
```

I would recommend using default values if you do not need specific versions.

## Options

| Option| Description|
|-----|----------|
| `--python-version=VERSION`          | Specify the [Python Version](https://www.python.org/ftp/python) to install (default: `3.8.19`). Only versions `3.8.x`, `3.9.x`, or `3.10.x` are allowed. |
| `--psychopy-version=VERSION`        | Specify the [PsychoPy Version](https://pypi.org/project/psychopy/#history) to install (default: `2024.1.1`). |
| `--wxpython-version=VERSION`        | Specify the [wxPython Version](https://pypi.org/project/wxPython/#history) to install (default: `latest`). |
| `--install-dir=DIR`                 | Specify the installation directory (default: `$HOME`); use absolute paths without a trailing `/`. Do not use `~/`; use `/home/{user}` instead. |
| `--no-versioned-install-dir`        | Installs directly into the specified `install-dir` without creating a versioned subdirectory. Requires `--install-dir`. |
| `--bids-version=VERSION`            | Specify the [PsychoPy_BIDS Version](https://pypi.org/project/psychopy_bids/#history) to install (default: None). |
| `--build=[python\|wxpython\|both]`  | Build Python and/or wxPython from source instead of downloading wheel/binaries. Use `both` if something does not work. Note: This process might take 1-2 hours. |
| `-f`, `--force`                     | Force overwrite of the existing installation directory. |
| `-v`, `--verbose`                   | Enable verbose output. |
| `--disable-shortcut`                | Disable desktop shortcut creation. |
|  `--disable-path`                   |   Disable adding psychopy to system path. |
| `-h`, `--help`                      | Show help message. |

**Note:**

- The default version for `--psychopy-version` is set to `2024.1.4` Because new releases for Linux often introduce bugs that require manual fixes. For example `2024.2.1` has problems with opening the GUI when not installing a earlier version first.
- `--psychopy-version`, `--wxpython-version` and `--bids-version` can take a actual pypi version,`latest` or `git` as argument. Git versions are not recommended because they can be unstable.

## Examples

- `./psychopy_linux_installer` (all default)
- `./psychopy_linux_installer --psychopy-version=2024.1.4 --install-dir=/home/user1 --bids-version=git --build=python -v -f`

## Script Details

The script performs the following steps:

- Detects the package manager (supports apt, yum, dnf, and pacman).
- Installs necessary dependencies.
- Creates a directory in the specified location for PsychoPy.
- Checks if the specified Python version exists if necessary downloads and install it as `altinstall`.
- Creates and activates a virtual environment for PsychoPy.
- Installs/builds wxPython.
- Upgrades pip and some pip packages.
- Install specified PsychoPy version.
- Adds the current user to a `psychopy` group and sets security limits.
- Creates a symbolic link to the PsychoPy executable in `.bin`.
- Creates a desktop shortcut.

## Post-Installation

After installation, desktop icons for PsychoPy will be created automatically, and the application will be added to your system's PATH as:

`psychopy_${PSYCHOPY_VERSION}_py_${PYTHON_VERSION}`

Refreshing your system's PATH is necessary.

You can also launch PsychoPy directly using the absolute path:

`${PSYCHOPY_DIR}/bin/psychopy`

**Note:**
All commands, along with the installed versions and set paths, as well as the command to refresh your system's PATH, will be displayed at the end of the script.

## To-Do

- Refactor actions and testscripts
- Conduct tests on a physical machine.
- Test with connected hardware components.
- Test on Pacman-based distributions.

## Links

- [PsychoPy Github](https://github.com/psychopy/psychopy)
- [PsychoPy_bids GitLab](https://gitlab.com/psygraz/psychopy-bids)

## Automated Installation, Test and build Results

[View the latest installation test results](https://github.com/wieluk/psychopy_linux_installer/blob/main/.github/installation_results.md)

[View the build results](https://github.com/wieluk/psychopy_linux_installer/blob/main/.github/build_results.md)


### Builds
[wxPython on Nextcloud](https://cloud.uni-graz.at/s/YtX33kbasHMZdgs)

[Python on Nextcloud](https://cloud.uni-graz.at/s/o4tnQgN6gjDs3CK)
