# Devin Desktop for Arch Linux

![Version](https://img.shields.io/badge/version-3.2.19-blue.svg)

This project repackages the official **Devin Desktop** Linux `.deb` for Arch Linux and derivatives like Manjaro.

**Latest Version Available:** `3.2.19`

Devin Desktop is the successor to Windsurf. The package name is now `devin-desktop-bin`, but it still provides a compatibility `windsurf` command symlink for existing shell scripts and workflows.

## Installation Methods

### Option 1: Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/BOTOOM/devin-bin-arch/main/install_windsurf | bash
```

**What this does:**

1. Clones this repository to a temporary directory.
2. Prompts you to choose between Standard and Electron versions.
3. Builds and installs the selected package using `makepkg`.
4. Replaces an installed `windsurf-bin` package if present.
5. Cleans up temporary files.

**Environment Variable:**

Set `DEVIN_INSTALL_CHOICE` to skip the prompt:

- `DEVIN_INSTALL_CHOICE=standard` for `devin-desktop-bin`
- `DEVIN_INSTALL_CHOICE=electron` for `devin-desktop-bin-electron-latest`

The old `WINDSURF_INSTALL_CHOICE` variable is still accepted for compatibility.

```bash
DEVIN_INSTALL_CHOICE=standard curl -sSL https://raw.githubusercontent.com/BOTOOM/devin-bin-arch/main/install_windsurf | bash
```

### Option 2: Local Maintenance (Docker Required)

Use this when you want to check the upstream Devin Desktop changelog yourself and rebuild locally.

**Prerequisites:**

- Docker
- `base-devel` package group

**Usage:**

```bash
git clone https://github.com/BOTOOM/devin-bin-arch.git
cd devin-bin-arch
./check_and_update_local.sh
```

**What this does:**

1. Builds a minimal Docker image.
2. Reads the Devin Desktop changelog and finds the newest Linux x64 `.deb` URL.
3. Downloads the `.deb` to calculate the SHA256 hash.
4. Updates `package/PKGBUILD` with the version, checksum, and full upstream URL.
5. Compares the package version with your installed version.
6. Asks if you want to build and install the update.

## Migrating from Windsurf with minimal disruption

The installed system files move from `/usr/share/windsurf` to `/usr/share/devin-desktop`, and the main command becomes `devin-desktop`. This package also installs `/usr/bin/windsurf` as a compatibility symlink.

According to the official Devin Desktop FAQ, Linux user data is migrated automatically on first launch:

| Data | Legacy path read by Devin | New path written by Devin |
| --- | --- | --- |
| IDE settings, keybindings, snippets, workspaces, global storage | `~/.config/Windsurf/` | `~/.config/Devin/` |
| Extensions | `~/.windsurf/extensions/` | `~/.devin/extensions/` |
| System-level rules, workflows, skills | `/etc/windsurf/` | `/etc/devin/` |
| Codeium/Windsurf user settings, MCP config, global workflows, global skills, CLI binaries | `~/.codeium/` | unchanged |

During the transition, Devin Desktop reads both legacy Windsurf paths and new Devin paths. New IDE and extension data is written to the Devin paths, while `~/.codeium/` intentionally keeps its existing structure, including subdirectories such as `~/.codeium/windsurf/global_workflows/`, `~/.codeium/windsurf/skills/`, and `~/.codeium/windsurf/bin/`. Do not rename or move `~/.codeium/windsurf` to a Devin path.

Before migrating, close Windsurf and make a backup:

```bash
mkdir -p "$HOME/windsurf-migration-backup"
cp -a "$HOME/.config/Windsurf" "$HOME/.windsurf" "$HOME/.windsurf-server" "$HOME/.codeium" "$HOME/windsurf-migration-backup/" 2>/dev/null || true
```

Then install Devin Desktop and launch it once:

```bash
devin-desktop
```

Do not pre-seed the new directories before the first launch. Let Devin Desktop do the official migration first. If extensions, settings, keybindings, snippets, or agent state are still missing after first launch, close Devin Desktop and copy only missing data:

```bash
mkdir -p "$HOME/.config/Devin" "$HOME/.devin" "$HOME/.devin-server"

rsync -a --ignore-existing "$HOME/.config/Windsurf/User/" "$HOME/.config/Devin/User/" 2>/dev/null || true
rsync -a --ignore-existing "$HOME/.config/Windsurf/globalStorage/" "$HOME/.config/Devin/globalStorage/" 2>/dev/null || true
rsync -a --ignore-existing "$HOME/.config/Windsurf/Workspaces/" "$HOME/.config/Devin/Workspaces/" 2>/dev/null || true
rsync -a --ignore-existing "$HOME/.windsurf/extensions/" "$HOME/.devin/extensions/" 2>/dev/null || true
rsync -a --ignore-existing "$HOME/.windsurf-server/" "$HOME/.devin-server/" 2>/dev/null || true
```

Keep the backup and old Windsurf folders until you confirm that extensions, login state, workspaces, rules, workflows, skills, and agent memories are present in Devin Desktop. Do not delete `~/.windsurf`, `~/.devin`, or `~/.codeium` during the transition; the FAQ says legacy Windsurf paths remain readable and the `~/.codeium` directory structure remains unchanged in this release.

## Project Structure

- `install_windsurf`: Standalone installation script used by the curl command.
- `check_and_update_local.sh`: Local maintenance script that orchestrates the Docker check and update process.
- `_install_local.sh`: Internal script used by `check_and_update_local.sh` to perform local installation.
- `update.sh`: Runs Docker and updates `package/PKGBUILD` from upstream Devin Desktop release data.
- `Dockerfile`: Docker configuration for the version checker container.
- `package/PKGBUILD`: Arch Linux package build description.
- `.github/workflows/update.yml`: GitHub Action that updates the `PKGBUILD` automatically.
- `scripts/check-windsurf-version.sh`: Version checker that reads the Devin Desktop changelog.

## Manual Installation

```bash
git clone https://github.com/BOTOOM/devin-bin-arch.git
cd devin-bin-arch/package

makepkg -sf
sudo pacman -U devin-desktop-bin-3.0.12-1-x86_64.pkg.tar.*
```

For the Electron package variant:

```bash
sudo pacman -U devin-desktop-bin-electron-latest-3.0.12-1-x86_64.pkg.tar.*
```

## Automated Updates

The update workflow runs on a schedule, checks the Devin Desktop changelog, and opens an automated PR when a newer Linux `.deb` is available.

## Notes

This PKGBUILD conflicts with old Windsurf packages because both own overlapping commands and desktop integrations. It provides `windsurf` and `windsurf-bin` for compatibility while installing Devin Desktop under its new upstream name.

## Disclaimer

This is an unofficial package. Devin Desktop and Windsurf are trademarks of their respective owners. This package repackages the official `.deb` file distributed by Cognition/Devin.

## License

The packaging scripts are licensed under MIT, while Devin Desktop itself has its own license terms.
