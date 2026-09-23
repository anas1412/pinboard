#!/usr/bin/env bash
# Install the latest Tackora on Linux:
#   curl -fsSL https://anas1412.github.io/tackora/install.sh | bash
# Arch: the tackora-bin AUR package (with yay or paru). Debian/Ubuntu: the .deb.
# Fedora/openSUSE: the .rpm. Anything else, or with --appimage: the AppImage in ~/.local/bin.
set -euo pipefail

repo="https://github.com/anas1412/tackora"
say() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ $(uname -s) == Linux ]] || fail "this installer is for Linux; on Windows download the installer from https://anas1412.github.io/tackora/download"
[[ $(uname -m) == x86_64 ]] || fail "Tackora is built for x86_64 only (this machine is $(uname -m))"
command -v curl >/dev/null || fail "curl is required"

sudo=""
if [[ $EUID -ne 0 ]]; then
  command -v sudo >/dev/null && sudo="sudo" || true
fi

# The release the "latest" link redirects to, like v0.3.1.
tag=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$repo/releases/latest")
tag=${tag##*/}
[[ $tag == v* ]] || fail "couldn't find the latest release at $repo/releases"
v=${tag#v}
dl="$repo/releases/download/$tag"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fetch() { say "Downloading $1"; curl -fL --progress-bar -o "$tmp/$1" "$dl/$1"; }

install_appimage() {
  local dir="$HOME/.local/bin"
  fetch "Tackora_${v}_amd64.AppImage"
  mkdir -p "$dir" "$HOME/.local/share/applications"
  install -m 755 "$tmp/Tackora_${v}_amd64.AppImage" "$dir/tackora"
  cat >"$HOME/.local/share/applications/tackora.desktop" <<EOF
[Desktop Entry]
Name=Tackora
Comment=A Kanban board for your coding agents
Exec=$dir/tackora
Terminal=false
Type=Application
Categories=Development;
EOF
  say "Installed the AppImage to $dir/tackora"
  [[ :$PATH: == *":$dir:"* ]] || say "Add $dir to your PATH to run 'tackora' from a terminal"
}

id_like=""
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  id_like=" ${ID:-} ${ID_LIKE:-} "
fi

if [[ ${1:-} == --appimage ]]; then
  install_appimage
elif [[ $id_like == *" arch "* ]] && command -v yay >/dev/null; then
  say "Installing tackora-bin from the AUR with yay"
  yay -S --needed tackora-bin
elif [[ $id_like == *" arch "* ]] && command -v paru >/dev/null; then
  say "Installing tackora-bin from the AUR with paru"
  paru -S --needed tackora-bin
elif [[ $id_like == *" debian "* || $id_like == *" ubuntu "* ]] && command -v apt-get >/dev/null; then
  fetch "Tackora_${v}_amd64.deb"
  chmod 644 "$tmp/Tackora_${v}_amd64.deb"
  $sudo apt-get install -y "$tmp/Tackora_${v}_amd64.deb"
elif [[ $id_like == *" fedora "* || $id_like == *" rhel "* ]] && command -v dnf >/dev/null; then
  fetch "Tackora-${v}-1.x86_64.rpm"
  $sudo dnf install -y "$tmp/Tackora-${v}-1.x86_64.rpm"
elif [[ $id_like == *" suse "* ]] && command -v zypper >/dev/null; then
  fetch "Tackora-${v}-1.x86_64.rpm"
  $sudo zypper --non-interactive install --allow-unsigned-rpm "$tmp/Tackora-${v}-1.x86_64.rpm"
else
  [[ $id_like == *" arch "* ]] && say "No AUR helper (yay or paru) found; installing the AppImage instead"
  install_appimage
fi

say "Tackora $v is installed. Open it from your app menu, or run: tackora"
if ! command -v claude >/dev/null && ! command -v opencode >/dev/null; then
  say "Tackora needs Claude Code or OpenCode 2: https://anas1412.github.io/tackora/guide/install"
fi
