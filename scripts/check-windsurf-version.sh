#!/bin/bash
set -euo pipefail

CHANGELOG_URL="${DEVIN_CHANGELOG_URL:-https://docs.devin.ai/desktop/changelog}"

TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

CHANGELOG_FILE="$TEMP_DIR/changelog.html"
curl -fsSL "$CHANGELOG_URL" -o "$CHANGELOG_FILE"

mapfile -t CANDIDATES < <(
    grep -oE 'https://[^"< ]+/Devin-linux-x64-[0-9]+\.[0-9]+\.[0-9]+\.deb' "$CHANGELOG_FILE" \
        | sed 's/&amp;/\&/g' \
        | awk -F'Devin-linux-x64-|\\.deb' '{ print $2 " " $0 }' \
        | sort -Vru
)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    echo "Failed to find a Devin Desktop Linux .deb URL in $CHANGELOG_URL" >&2
    exit 1
fi

LATEST="${CANDIDATES[0]}"
VERSION="${LATEST%% *}"
DEB_URL="${LATEST#* }"
DEB_FILE="$TEMP_DIR/Devin-linux-x64-${VERSION}.deb"

curl -fsSL "$DEB_URL" -o "$DEB_FILE"
SHA256SUM=$(sha256sum "$DEB_FILE" | awk '{print $1}')

printf "%s %s %s" "$VERSION" "$SHA256SUM" "$DEB_URL"
