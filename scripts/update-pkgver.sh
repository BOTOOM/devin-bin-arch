#!/bin/bash
set -euo pipefail

# Update PKGBUILD from the latest Devin Desktop release metadata.
# Usage: ./update-pkgver.sh [package-name]

if [ $# -gt 1 ]; then
    echo "Usage: $0 [package-name]"
    exit 1
fi

PACKAGE=${1:-devin-desktop-bin}
PKGBUILD_PATH="package/PKGBUILD"

if [ ! -f "$PKGBUILD_PATH" ]; then
    echo "Error: PKGBUILD not found for package $PACKAGE"
    exit 1
fi

CHECK_OUTPUT=$(./scripts/check-windsurf-version.sh)
VERSION=$(echo "$CHECK_OUTPUT" | awk '{print $1}')
SHA256SUM=$(echo "$CHECK_OUTPUT" | awk '{print $2}')
DEB_URL=$(echo "$CHECK_OUTPUT" | awk '{print $3}')

if [ -z "$VERSION" ] || [ -z "$SHA256SUM" ] || [ -z "$DEB_URL" ]; then
    echo "Error: could not parse version metadata: $CHECK_OUTPUT" >&2
    exit 1
fi

# Update pkgver in PKGBUILD
sed -i "s/^pkgver=.*$/pkgver=$VERSION/" "$PKGBUILD_PATH"

# Reset pkgrel to 1
sed -i "s/^pkgrel=.*$/pkgrel=1/" "$PKGBUILD_PATH"

# Update full source URL and checksum. Devin Desktop URLs include a build hash.
sed -i "s|source=(\"[^\"]*\"|source=(\"$DEB_URL\"|" "$PKGBUILD_PATH"
sed -i "/^sha256sums=('/s/'[^']*'/'$SHA256SUM'/" "$PKGBUILD_PATH"

echo "Updated $PACKAGE to version $VERSION"
