# Windsurf for Arch Linux

![Version](https://img.shields.io/badge/version-2.2.17-blue.svg)

This project allows you to install **Windsurf**, Codeium's advanced AI-powered IDE, on Arch Linux (and derivatives like Manjaro).

**Latest Version Available:** `2.2.17`

It provides two methods for installation: a quick automated install using the repository's latest info, or a local maintenance mode using Docker to fetch the absolute latest version directly from Codeium.

## What is Windsurf?

[Windsurf](https://windsurf.com/) (formerly Codeium) is an advanced AI coding assistant for developers and enterprises. Windsurf Editor is the first AI-native IDE designed to keep developers in flow with intelligent code completion, chat, and code navigation features.

## Installation Methods

### Option 1: Quick Install (Recommended)
This method uses the `PKGBUILD` hosted in this repository, which is automatically updated by GitHub Actions.

```bash
curl -sSL https://raw.githubusercontent.com/BOTOOM/windsurf-bin-arch/main/install_windsurf | bash
```

**What this does:**
1. Clones this repository to a temporary directory.
2. Checks if you have `windsurf-bin` installed.
3. Prompts you to choose between Standard and Electron versions.
4. Builds and installs the package using `makepkg`.
5. Cleans up temporary files.

**Environment Variable:**
You can set `WINDSURF_INSTALL_CHOICE` to skip the prompt:
- `WINDSURF_INSTALL_CHOICE=standard` for Standard version
- `WINDSURF_INSTALL_CHOICE=electron` for Electron version

Example:
```bash
WINDSURF_INSTALL_CHOICE=standard curl -sSL https://raw.githubusercontent.com/BOTOOM/windsurf-bin-arch/main/install_windsurf | bash
```

### Option 2: Local Maintenance (Docker Required)
If you want to check for updates directly from Codeium yourself (e.g., if the repository hasn't updated yet), you can use the local Docker-based scripts.

**Prerequisites:**
- Docker
- `base-devel` package group

**Usage:**
1. Clone the repository:
   ```bash
   git clone https://github.com/BOTOOM/windsurf-bin-arch.git
   cd windsurf-bin-arch
   ```

2. Run the local check and update script:
   ```bash
   ./check_and_update_local.sh
   ```

**What this does:**
1. Builds a minimal Ubuntu Docker image.
2. Queries Codeium's APT repository inside the container to get the latest version, SHA256 hash, and download URL.
3. Updates the local `package/PKGBUILD` file with this new information.
4. Compares the new version with your installed version.
5. Asks if you want to build and install the update immediately.

## Project Structure

- `install_windsurf`: The standalone installation script used by the curl command.
- `check_and_update_local.sh`: Local maintenance script that orchestrates the Docker check and update process.
- `_install_local.sh`: Internal script used by `check_and_update_local.sh` to perform the actual installation.
- `update.sh`: The core logic that runs the Docker container to fetch version info.
- `Dockerfile`: Docker configuration for the version checker container.
- `package/PKGBUILD`: The Arch Linux package build description file.
- `.github/workflows/update.yml`: GitHub Action that runs periodically to update the `PKGBUILD` in this repository automatically.
- `scripts/check-windsurf-version.sh`: Script that queries Codeium's repository for version information.

## Manual Installation

```bash
# Clone the AUR package
git clone https://aur.archlinux.org/windsurf-bin.git
cd windsurf-bin

# Build and install either the native or electron version
makepkg -si windsurf-bin
# or
makepkg -si windsurf-bin-electron-latest
```

## Automated Updates

This PKGBUILD uses GitHub Actions to automate maintenance:

1. **Version Checking and Publishing** (`update.yml`)

   - Runs every 3 hours to check for new upstream versions
   - Creates and auto-merges pull requests when updates are available
   - Updates README.md with new version information

2. **AUR Publishing** (`publish.yml`) (disabled)
   - Reusable workflow called by the update workflow
   - Publishes the updated package to the AUR
   - Can also be manually triggered when needed

## Note

This PKGBUILD conflicts with the `windsurf` AUR package, as both cannot be installed simultaneously. The reason why this PKGBUILD exist is due to the fact that the `windsurf` AUR package is slow in updating to the latest version and people want to use the latest version of Windsurf as soon as it is available.

## Issues

If you encounter any problems with this PKGBUILD:

1. [Open an issue](https://github.com/BOTOOM/windsurf-bin-arch/issues) in this repository
2. Comment on the [AUR package page](https://aur.archlinux.org/packages/windsurf-bin-arch)

## Disclaimer

This is an unofficial package. Windsurf is a trademark of Codeium.
This package repackages the official `.deb` file distributed by Codeium.

## License

The packaging scripts are licensed under MIT, while Windsurf itself has its own license terms.
