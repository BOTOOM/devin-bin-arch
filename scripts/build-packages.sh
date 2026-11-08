#!/bin/bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_UID=$(stat -c '%u' "$REPO_ROOT/package")
BUILD_GID=$(stat -c '%g' "$REPO_ROOT/package")

if [[ "$BUILD_UID" == 0 ]]; then
    printf 'Run this script as a non-root user so package files retain the checkout ownership.\n' >&2
    exit 1
fi

docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -e BUILD_UID="$BUILD_UID" \
    -e BUILD_GID="$BUILD_GID" \
    -w /workspace/package \
    archlinux:base-devel bash -euo pipefail -c '
        pacman -Syu --noconfirm
        if ! getent group "$BUILD_GID" > /dev/null; then
            groupadd --gid "$BUILD_GID" builder
        fi
        useradd --create-home --non-unique --uid "$BUILD_UID" --gid "$BUILD_GID" builder
        printf "builder ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/builder
        if [ -f /workspace/upstream.deb ]; then
            source PKGBUILD
            sudo -u builder cp /workspace/upstream.deb "Devin-linux-x64-${pkgver}.deb"
        fi
        sudo -u builder makepkg --syncdeps --noconfirm --cleanbuild --force
        bash /workspace/tests/package-layout.sh
        source PKGBUILD
        pacman -Si "electron$(cat src/electron-major)" electron > /dev/null
        sudo -u builder bash -euo pipefail -c '\''
            source PKGBUILD
            for name in "${pkgname[@]}"; do
                package="${name}-${pkgver}-${pkgrel}-x86_64.pkg.tar.zst"
                bsdtar -tf "$package" > "$package.files"
                bsdtar -xOf "$package" .PKGINFO > "$package.info"
                grep -Fx "usr/bin/devin-desktop" "$package.files"
                grep -Fx "usr/bin/windsurf" "$package.files"
                runtime=electron
                if [[ "$name" == devin-desktop-bin ]]; then
                    runtime+="$(cat src/electron-major)"
                fi
                grep -Fx "depend = $runtime" "$package.info"
                bsdtar -xOf "$package" usr/bin/devin-desktop | grep -Fx "name=$runtime"
            done
        '\''
    '
