This repository contains a script to install PsychoPy on various Linux distributions, including Ubuntu (20.04, 22.04, 24.04), Pop!_OS 22.04, and Debian 12. The installation has been tested in VirtualBox environments.

## Features

- Supports Ubuntu 20.04, 22.04, 24.04, Pop!_OS 22.04, and Debian 12.
- Installs specified versions of Python and PsychoPy.
- Creates a virtual environment for PsychoPy.
- Option to install the latest or specific versions of PsychoPy.
- Ensures necessary dependencies are installed.
- Sets up system configurations for optimal PsychoPy performance.

## Usage

### Prerequisites

- A supported Linux distribution (Ubuntu 20.04, 22.04, 24.04, Pop!_OS 22.04, Debian 12).
- Administrative (sudo) privileges.

### Installation

1. Clone this repository:

   \```bash
   git clone https://github.com/yourusername/psychopy-install-script.git
   cd psychopy-install-script
   \```

2. Make the script executable:

   \```bash
   chmod +x install_psychopy_ubuntu.sh
   \```

3. Run the script with desired options:

   \```bash
   ./install_psychopy_ubuntu.sh [options]
   \```

   #### Options:

   - `--python_version=VERSION` - Specify the Python version to install (default: 3.8.16).
   - `--psychopy_version=VERSION` - Specify the PsychoPy version to install (default: latest). Use `git` for the latest GitHub version.
   - `-f, --force` - Force overwrite of the existing installation directory.
   - `-h, --help` - Show the help message.

   Example:

   \```bash
   ./install_psychopy_ubuntu.sh --python_version=3.9.1 --psychopy_version=2021.2.3
   \```

### Post-Installation

To apply the changes to your shell environment, run:

\```bash
source ~/.bashrc
\```

To start PsychoPy, use the command created during installation:

\```bash
psychopy_v<psychopy_version>_py_v<python_version>
\```

### Uninstallation

To remove the installed PsychoPy environment, simply delete the created directory:

\```bash
rm -rf ~/psychopy_v<psychopy_version>_py_v<python_version>
\```

## Contributing

Contributions are welcome! Please submit pull requests or issues as needed.

## License

This project is licensed under the MIT License.

## Acknowledgments

- [PsychoPy](https://www.psychopy.org/)
- [Ubuntu](https://ubuntu.com/)
- [Pop!_OS](https://pop.system76.com/)
- [Debian](https://www.debian.org/)
""")
