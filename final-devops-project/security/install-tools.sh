#!/usr/bin/env bash
# install-tools.sh <tool>...   tools: gitleaks trivy
#
# Downloads pinned release binaries and verifies them against sha256 sums that
# are written HERE, not fetched from the same release page. A swapped or
# tampered release fails the check instead of running inside the pipeline.
set -euo pipefail

case "$(uname -m)" in
  x86_64)        A=amd64 ;;
  aarch64|arm64) A=arm64 ;;
  *) echo "unsupported arch $(uname -m)"; exit 1 ;;
esac
DEST="${TOOLS_DIR:-$HOME/.local/bin}"
mkdir -p "$DEST"
TMP=$(mktemp -d)

fetch() {  # fetch <url> <sha256> <file>
  curl -fsSL "$1" -o "$TMP/$3"
  echo "$2  $TMP/$3" | sha256sum -c --quiet - || { echo "checksum mismatch for $3"; exit 1; }
}

for tool in "$@"; do
  case "$tool:$A" in
    gitleaks:amd64) fetch https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz 551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb g.tgz ;;
    gitleaks:arm64) fetch https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_arm64.tar.gz e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080 g.tgz ;;
    trivy:amd64)    fetch https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_Linux-64bit.tar.gz 2ae6fe3ee734b7fdf11335663e18c75ea12dccc76062f09f164a3b0f8be4371a t.tgz ;;
    trivy:arm64)    fetch https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_Linux-ARM64.tar.gz b94ce1976bbf3c15b514b605ee88be7c6d94a29be2302847ff01cb794d47aad5 t.tgz ;;
    *) echo "unknown tool $tool"; exit 1 ;;
  esac
  case "$tool" in
    gitleaks) tar -xzf "$TMP/g.tgz" -C "$TMP" gitleaks && install "$TMP/gitleaks" "$DEST/" ;;
    trivy)    tar -xzf "$TMP/t.tgz" -C "$TMP" trivy && install "$TMP/trivy" "$DEST/" ;;
    *)        install "$TMP/$tool" "$DEST/$tool" ;;
  esac
  echo "installed $tool ($A, sha256 verified) -> $DEST/$tool"
done
rm -rf "$TMP"
