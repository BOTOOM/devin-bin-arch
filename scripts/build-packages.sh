#!/bin/bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

docker run --rm \
    -v "$REPO_ROOT:/workspace" \
    -w /workspace/package \
    archlinux:base-devel bash -euo pipefail -c '
        pacman -Syu --noconfirm
        useradd -m builder
        printf "builder ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/builder
        if [ -f /workspace/upstream.deb ]; then
            source PKGBUILD
            cp /workspace/upstream.deb "Devin-linux-x64-${pkgver}.deb"
        fi
        chown -R builder:builder /workspace/package
        sudo -u builder makepkg --syncdeps --noconfirm --cleanbuild
        bash /workspace/tests/package-layout.sh
        source PKGBUILD
        pacman -Si "electron$(cat src/electron-major)" electron > /dev/null
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
    '
