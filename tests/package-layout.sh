#!/bin/bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

error() {
    printf 'ERROR: %s\n' "$*" >&2
}

test_layout() (
    local modules=$1 ripgrep=$2 desktop_file=$3 failure=${4:-}
    local work="$TEST_ROOT/$modules-$ripgrep-$desktop_file-${failure:-success}"
    mkdir -p "$work/archive"
    cd "$work/archive"
    local app=usr/share/devin-desktop/resources/app
    local rg_path="$app/$modules/@vscode/$ripgrep/bin"
    if [[ "$ripgrep" == ripgrep-universal ]]; then
        rg_path+=/linux-x64
    fi
    mkdir -p "$rg_path" "$app/extensions/windsurf/bin" "$app/out/media" usr/share/applications
    printf 'Chrome/150.0.7871.250 Electron/43.8.3\n' > usr/share/devin-desktop/devin-desktop
    if [[ "$failure" == electron ]]; then
        printf 'No runtime version\n' > usr/share/devin-desktop/devin-desktop
    elif [[ "$failure" == ambiguous-electron ]]; then
        printf 'Chrome/150.0.0.0 Electron/44.0.0\n' >> usr/share/devin-desktop/devin-desktop
    fi
    printf '{}\n' > "$app/package.json"
    printf '<svg/>\n' > "$app/out/media/code-icon.svg"
    touch "$app/extensions/windsurf/bin/fd"
    if [[ "$failure" != ripgrep ]]; then
        touch "$rg_path/rg"
    fi
    if [[ "$modules" == node_modules ]]; then
        mkdir -p "$app/node_modules/open"
        touch "$app/node_modules/open/xdg-open"
    else
        touch "$app/node_modules.asar"
    fi
    if [[ "$failure" != handler ]]; then
        printf '[Desktop Entry]\nName=Devin URL Handler\nType=Application\nExec=devin-desktop --open-url %%U\n' \
            > "usr/share/applications/$desktop_file"
    fi
    tar -cJf "$work/data.tar.xz" ./usr
    cd "$work"
    printf 'name=electron\n/usr/lib/code/out/cli.js\n/usr/lib/code/code.mjs\n' > code.sh
    source "$REPO_ROOT/package/PKGBUILD"
    if [[ -n "$failure" ]]; then
        if (set -e; build) > build.log 2>&1; then
            printf 'Expected failure for %s\n' "$failure" >&2
            exit 1
        fi
        case "$failure" in
            electron|ambiguous-electron) grep -F 'Could not determine a unique Electron major version' build.log ;;
            ripgrep) grep -F 'Bundled ripgrep binary location not found' build.log ;;
            handler) grep -F 'URL handler desktop file was not found' build.log ;;
        esac
        exit 0
    fi
    build
    [[ "$(cat electron-major)" == 43 ]]
    [[ "$(readlink "$rg_path/rg")" == /usr/bin/rg ]]
    [[ "$(readlink "$app/extensions/windsurf/bin/fd")" == /usr/bin/fd ]]
    if [[ "$modules" == node_modules ]]; then
        [[ "$(readlink "$app/node_modules/open/xdg-open")" == /usr/bin/xdg-open ]]
    else
        [[ -f "$app/node_modules.asar" ]]
        [[ ! -e "$app/node_modules/open/xdg-open" ]]
    fi
    grep -Fx 'Hidden=true' "usr/share/applications/$desktop_file"
    local base_depends=("${depends[@]}")
    pkgdir="$work/standard"
    mkdir -p "$pkgdir"
    package_devin-desktop-bin
    grep -Fx 'name=electron43' "$pkgdir/usr/bin/devin-desktop"
    [[ "$(readlink "$pkgdir/usr/bin/windsurf")" == devin-desktop ]]
    [[ " ${depends[*]} " == *" electron43 "* ]]
    depends=("${base_depends[@]}")
    pkgdir="$work/latest"
    mkdir -p "$pkgdir"
    package_devin-desktop-bin-electron-latest
    grep -Fx 'name=electron' "$pkgdir/usr/bin/devin-desktop"
    [[ "$(readlink "$pkgdir/usr/bin/windsurf")" == devin-desktop ]]
    [[ " ${depends[*]} " == *" electron "* ]]
)

for modules in node_modules node_modules.asar.unpacked; do
    for ripgrep in ripgrep ripgrep-universal; do
        for handler in devin-desktop-url-handler.desktop devin-desktop.UrlHandler.desktop; do
            test_layout "$modules" "$ripgrep" "$handler"
        done
    done
done
for failure in electron ambiguous-electron ripgrep handler; do
    test_layout node_modules.asar.unpacked ripgrep-universal devin-desktop.UrlHandler.desktop "$failure"
done
printf 'All package layout tests passed.\n'
