# PsychoPy Installation Script for Linux

This script installs PsychoPy on various Linux distributions, including:

- Ubuntu 24.04, 22.04, 20.04
- PopOS 22.04
- Debian 12
- CentOS 9

Additional distributions may be tested and supported in the future.
All tests are done on Virtual Machines only.

## Info

- Installs the specified or default Python version as `altinstall`.
- Creates a directory in given directory (default ~):
  `{install_dir}/psychopy_v${PSYCHOPY_VERSION}_py_v${PYTHON_VERSION}`

## Usage

- `git clone https://github.com/wieluk/psychopy_linux_installer.git`
- `cd psychopy_linux_installer`
- ``chmod +x psychopy_linux_installer.sh``
- `./psychopy_linux_installer.sh [options] `

## Options

- --python_version=VERSION : Specify the Python version to install (default: 3.8.16).
- --psychopy_version=VERSION : Specify the PsychoPy version to install (default: latest); use git for the latest GitHub version.
- --install_dir=DIR : Specify the installation directory (default: ~)
- -f, --force : Force overwrite of the existing installation directory.
- -h, --help : Show this help message.

## Example

- `./install_psychopy.sh` (all default)
- `./install_psychopy.sh --python_version=3.8.16 --psychopy_version=2024.1.5 --install_dir==/home/user1`

## Script Details

The script performs the following steps:

- Detects the package manager (supports apt, yum, dnf, and pacman).
- Installs necessary dependencies.
- Checks if the specified Python version exists and downloads it if necessary.
- Determines the PsychoPy version to install:
- If latest, it fetches the latest version from PyPI.
- If git, it installs PsychoPy from the latest GitHub repository.
- Creates a directory in the home directory for PsychoPy.
- Downloads and installs the specified Python version as altinstall.
- Creates and activates a virtual environment for PsychoPy.
- Upgrades pip and setuptools, and installs wxPython.
- Installs PsychoPy.
- Adds the current user to a psychopy group and sets security limits.
- Creates a symbolic link to the PsychoPy executable in .bin

## Post-Installation

To apply the changes, run:

`source ~/.bashrc`


To start PsychoPy, use:


`psychopy_v${PSYCHOPY_VERSION}_py_v${PYTHON_VERSION}` (also shown at end of the script)

## Notes

- There might be still packages missing for extended features.
- Maybe some installed dependencies are not neccesary; I still have to figure out what we don't need.
- Only very basic tests of actual PsychoPy components were performed.
- I did not test any distro with pacman package manger yet.
