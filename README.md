# Run 8 V3 Wine Installer

An idempotent Bash script to automate the installation of **Run 8 V3** (a train simulator) and its DLC packages on Linux using Wine (a Windows compatibility layer).

## Features

- **Idempotent installation**: Run the script multiple times safely—it tracks completed installations and skips them
- **DLC management**: Automatically detects and installs any new DLC added to the installer directory
- **Automatic DLC migration**: Recompiles the game and runs the updater when new DLC is detected
- **Interactive confirmation**: Prompts you to confirm installer success (useful since Wine exit codes can be unreliable)
- **Comprehensive logging**: All installation steps are logged to a file for debugging
- **Status reporting**: View installation status at any time without making changes
- **Dry-run mode**: Preview what will be installed before running the full installation

## Prerequisites

- **Linux** 
- **Wine** installed and available in your PATH
- **Bash** (version 4.0+)
- Write permissions to the installation directory (default: `$HOME/Games/Run8`)
- A Windows installation (`.exe`) of Run 8 V3 and any desired DLC installers

## Installation

1. Clone or download this repository to your local machine
2. Place your Run 8 V3 installer (`run8v3_install.exe`) and any DLC installer files in the same directory as `install-run8.sh`
3. Make the script executable:
   ```bash
   chmod +x install-run8.sh
   ```

## Usage

### Basic Installation

```bash
./install-run8.sh
```

Runs the full installation process:
- Creates a Wine prefix (virtual Windows environment)
- Installs Run 8 V3 base installation
- Creates a V2 compatibility file (needed for older DLC)
- Installs the Run 8 updater
- Detects and installs any DLC files
- Runs DLC migration if new DLC was installed

### View Installation Status

```bash
./install-run8.sh --status
```

Displays the current installation state:
- Whether base installation is complete
- Whether the updater is installed
- Which DLC files have been installed
- Whether critical files exist at expected locations

### Preview Changes (Dry Run)

```bash
./install-run8.sh --dry-run
```

Shows what would be installed without making any changes:
- Which installers would run
- Which installers would be skipped
- Whether DLC migration would occur

### Run Only the Updater

```bash
./install-run8.sh --update
```

Runs only the Run8_Updater.exe without modifying other components. Useful for updating an existing installation.

### Display Help

```bash
./install-run8.sh --help
```

Shows usage information and available options.

## Configuration

### Installation Directory

By default, Run 8 V3 is installed to `$HOME/Games/Run8`. To use a different location, set the `RUN8_ROOT` environment variable:

```bash
RUN8_ROOT=/path/to/custom/location ./install-run8.sh
```

### Key Paths

Within the installation root, the script creates:

- **`prefix/`** — Wine prefix (virtual Windows environment)
- **`prefix/drive_c/Run8Studios/Run8 Train Simulator V3/`** — Game installation directory
- **`manifest.txt`** — Tracks which installers have been run (do not delete unless resetting)
- **`install.log`** — Detailed log of all installation steps

## How It Works

### Idempotent Design

The script maintains a **manifest file** (`manifest.txt`) that records each installer's name and timestamp after successful completion. Before running an installer, the script checks if it's in the manifest:

- **If found**: The installer is skipped (already installed)
- **If not found**: The installer runs, and you confirm success before it's added to the manifest

This design allows you to:
1. Run the installer with DLC A and DLC B
2. Add DLC C to the directory later
3. Run the script again—only DLC C will install

### DLC Migration

When new DLC is detected:
1. Each new DLC installer runs
2. The base Run 8 V3 installer reruns (necessary for V2 DLC registration)
3. The Run 8 updater runs to finalize the installation

## Troubleshooting

### Wine is not installed

Install Wine on your system. On Ubuntu/Debian:
```bash
sudo apt install wine wine32 wine64
```

### Installer hangs or fails

The script will prompt you to confirm success. If the installer appears stuck:
1. Check the Wine window for dialogs or errors
2. If needed, choose `[r] Run the installer again` to retry
3. Check `install.log` for detailed error messages

### Re-run a failed installer

Edit `manifest.txt` and remove the line for the installer you want to retry, then run the script again.

### Custom installation path not working

Ensure the path exists and you have write permissions:
```bash
RUN8_ROOT=/path/to/custom mkdir -p "$RUN8_ROOT"
```

### Check the logs

All installation output is saved to `install.log` in the installation root. Review this file for detailed error messages:
```bash
cat ~/Games/Run8/install.log
```

## Project Structure

```
Run8Installer/
├── install-run8.sh      # Main installation script
├── LICENSE              # MIT License file
└── README.md            # This file
```

Place Run 8 installer files (`.exe`) in the same directory as `install-run8.sh`.

## License

This project is provided as-is. Run 8 Train Simulator is a product of Run 8 Studios.

## Support

For issues with Run 8 or Wine, consult:
- [Run 8 Studios Official Website](https://run8studios.com/)
- [Run 8 Studios Official Support Website](https://run8support.com/)
- [Wine Documentation](https://wiki.winehq.org/)

For issues with this script, check `install.log` for detailed error messages.
