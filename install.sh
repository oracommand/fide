#!/bin/sh
set -e

# ─────────────────────────────────────────────
#  fide — Finance IDE installer
#  Usage: curl -sSL https://oracommand.com/fide/install.sh | sh
# ─────────────────────────────────────────────

BINARY="fide"
REPO="oracommand/fide"
INSTALL_DIR="/usr/local/bin"
GITHUB_API="https://api.github.com/repos/${REPO}/releases/latest"

# ── Colours ──────────────────────────────────
if [ -t 1 ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  CYAN="\033[36m"
  GREEN="\033[32m"
  RED="\033[31m"
  RESET="\033[0m"
else
  BOLD="" DIM="" CYAN="" GREEN="" RED="" RESET=""
fi

print_header() {
  echo ""
  printf "${CYAN}${BOLD}  finance-ide${RESET}\n"
  printf "${DIM}  AI agent harness for financial markets${RESET}\n"
  echo ""
}

print_step() {
  printf "${CYAN}  →${RESET} $1\n"
}

print_ok() {
  printf "${GREEN}  ✓${RESET} $1\n"
}

print_error() {
  printf "${RED}  ✗${RESET} $1\n" >&2
}

# ── Detect OS ────────────────────────────────
detect_os() {
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$OS" in
    linux)  echo "linux"  ;;
    darwin) echo "darwin" ;;
    *)
      print_error "Unsupported OS: $OS"
      exit 1
      ;;
  esac
}

# ── Detect Arch ──────────────────────────────
detect_arch() {
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)           echo "amd64" ;;
    aarch64 | arm64)  echo "arm64" ;;
    *)
      print_error "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
}

# ── Fetch latest version tag ─────────────────
fetch_latest_version() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$GITHUB_API" 2>/dev/null | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
  else
    print_error "curl is required but not installed."
    exit 1
  fi
}

# ── Download binary ───────────────────────────
download_binary() {
  VERSION="$1"
  TARGET="$2"
  URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARGET}"

  TMP_FILE=$(mktemp)
  print_step "Downloading ${TARGET} (${VERSION})..."

  if ! curl -fsSL "$URL" -o "$TMP_FILE"; then
    print_error "Download failed: $URL"
    rm -f "$TMP_FILE"
    exit 1
  fi

  echo "$TMP_FILE"
}

# ── Install binary ────────────────────────────
install_binary() {
  TMP_FILE="$1"
  chmod +x "$TMP_FILE"

  if mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY}" 2>/dev/null; then
    print_ok "Installed to ${INSTALL_DIR}/${BINARY}"
  else
    # Need sudo
    print_step "Requesting sudo to install to ${INSTALL_DIR}..."
    if sudo mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY}" 2>/dev/null; then
      print_ok "Installed to ${INSTALL_DIR}/${BINARY}"
    else
      # Fall back to home directory
      HOME_BIN="$HOME/.local/bin"
      mkdir -p "$HOME_BIN"
      mv "$TMP_FILE" "${HOME_BIN}/${BINARY}"
      chmod +x "${HOME_BIN}/${BINARY}"
      print_ok "Installed to ${HOME_BIN}/${BINARY}"
      echo ""
      printf "${DIM}  Add to PATH if not already:${RESET}\n"
      printf "${DIM}  export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}\n"
    fi
  fi
}

# ── Main ─────────────────────────────────────
main() {
  print_header

  OS=$(detect_os)
  ARCH=$(detect_arch)
  TARGET="${BINARY}-${OS}-${ARCH}"

  print_step "Detected: ${OS}/${ARCH}"

  VERSION=$(fetch_latest_version)
  if [ -z "$VERSION" ]; then
    print_error "Could not determine latest version. Check your connection."
    exit 1
  fi

  TMP_FILE=$(download_binary "$VERSION" "$TARGET")
  install_binary "$TMP_FILE"

  echo ""
  print_ok "fide ${VERSION} ready!"
  echo ""
  printf "${BOLD}  Get started:${RESET}\n"
  printf "  fide               ${DIM}# launch finance-ide${RESET}\n"
  printf "  fide update        ${DIM}# update to latest version${RESET}\n"
  printf "  fide --help        ${DIM}# show all commands${RESET}\n"
  echo ""
  printf "${DIM}  Docs: https://oracommand.com/fide${RESET}\n"
  echo ""
}

main "$@"
