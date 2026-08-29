#!/bin/sh
# Install the `yandex` command from a published release.
#
#   curl -LsSf https://raw.githubusercontent.com/AntonLisovoy/yandex-cli/main/install.sh | sh
#
# Overridable for testing: YANDEX_CLI_BASE_URL, YANDEX_CLI_INSTALL_DIR,
# YANDEX_CLI_BIN_DIR.
set -eu

REPO="AntonLisovoy/yandex-cli"
BASE_URL="${YANDEX_CLI_BASE_URL:-https://github.com/${REPO}/releases/download}"
INSTALL_DIR="${YANDEX_CLI_INSTALL_DIR:-${HOME}/.local/share/yandex-cli}"
BIN_DIR="${YANDEX_CLI_BIN_DIR:-${HOME}/.local/bin}"

die() {
  echo "install.sh: $*" >&2
  exit 1
}

detect_target() {
  os="$(uname -s)"
  arch="$(uname -m)"
  case "${os}" in
    Darwin) os="macos" ;;
    Linux) os="linux" ;;
    *) die "unsupported OS: ${os}" ;;
  esac
  case "${arch}" in
    arm64 | aarch64) arch="arm64" ;;
    x86_64 | amd64) arch="x86_64" ;;
    *) die "unsupported architecture: ${arch}" ;;
  esac
  case "${os}-${arch}" in
    macos-arm64 | linux-x86_64) ;;
    *) die "no build for ${os}-${arch}; see https://github.com/${REPO}/releases" ;;
  esac
  echo "${os}-${arch}"
}

latest_version() {
  curl -LsSf "https://api.github.com/repos/${REPO}/releases/latest" \
    | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' \
    | head -1
}

verify_checksum() {
  # $1 archive path, $2 sums path, $3 archive filename
  expected="$(grep " \{1,2\}\*\{0,1\}${3}\$" "$2" | awk '{print $1}' | head -1)"
  test -n "${expected}" || die "no checksum recorded for ${3}"

  if command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$1" | awk '{print $1}')"
  elif command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$1" | awk '{print $1}')"
  else
    die "neither shasum nor sha256sum is available"
  fi

  test "${expected}" = "${actual}" \
    || die "checksum mismatch for ${3}: expected ${expected}, got ${actual}"
}

main() {
  command -v curl >/dev/null 2>&1 || die "curl is required"
  command -v tar >/dev/null 2>&1 || die "tar is required"

  target="$(detect_target)"
  version="${1:-$(latest_version)}"
  test -n "${version}" || die "could not determine the latest version"

  name="yandex-cli-${version}-${target}"
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" EXIT

  echo "Downloading ${name}..."
  curl -LsSf "${BASE_URL}/v${version}/${name}.tar.gz" -o "${tmp}/${name}.tar.gz" \
    || die "download failed"
  curl -LsSf "${BASE_URL}/v${version}/SHA256SUMS" -o "${tmp}/SHA256SUMS" \
    || die "could not fetch SHA256SUMS"

  verify_checksum "${tmp}/${name}.tar.gz" "${tmp}/SHA256SUMS" "${name}.tar.gz"

  tar -xzf "${tmp}/${name}.tar.gz" -C "${tmp}"
  test -x "${tmp}/${name}/yandex" || die "the archive has no launcher"

  mkdir -p "${INSTALL_DIR}" "${BIN_DIR}"

  # Copy into the destination filesystem first, so a failure here cannot
  # destroy an installed version: everything after this is a rename within
  # one filesystem.
  staging="${INSTALL_DIR}/.staging-${version}.$$"
  rm -rf "${staging}"
  cp -R "${tmp}/${name}" "${staging}" || die "could not write to ${INSTALL_DIR}"

  previous=""
  if [ -d "${INSTALL_DIR}/${version}" ]; then
    previous="${INSTALL_DIR}/.previous-${version}.$$"
    mv "${INSTALL_DIR}/${version}" "${previous}" \
      || die "could not move the installed version aside in ${INSTALL_DIR}"
  fi
  mv "${staging}" "${INSTALL_DIR}/${version}" || die \
    "could not put the new version in place; the previous one is at ${previous:-none}"
  [ -n "${previous}" ] && rm -rf "${previous}"

  ln -sf "${INSTALL_DIR}/${version}/yandex" "${BIN_DIR}/yandex" \
    || die "could not link ${BIN_DIR}/yandex"

  echo "Installed yandex ${version} to ${BIN_DIR}/yandex"

  case ":${PATH}:" in
    *":${BIN_DIR}:"*) ;;
    *) echo "" ; echo "Note: ${BIN_DIR} is not on your PATH. Add it:" ;
       echo "  export PATH=\"${BIN_DIR}:\$PATH\"" ;;
  esac
}

main "$@"
