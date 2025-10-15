#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ====================== Argument parsing ======================
VERBOSE=0
REQUESTED_TOOLS=()
NO_COLORS=0
DRY_RUN=0
DRY_RUN_SHOW_ALL=0

# ====================== Helpers  ==============================
debug() {
  if [ "${VERBOSE:-0}" -eq 1 ]; then
    printf '%s\n' "$*" >&2
  fi
}

err() {
  if [ "$NO_COLORS" -eq 0 ]; then
    printf '%b\n' "${RED}ERROR:${RESET} $*" >&2
  else
    printf 'ERROR: %s\n' "$*" >&2
  fi
}

warn() {
  if [ "$NO_COLORS" -eq 0 ]; then
    printf '%b\n' "${YELLOW}WARN:${RESET} $*" >&2
  else
    printf 'WARN: %s\n' "$*" >&2
  fi
}

log() {
  printf '%s\n' "$*" >&2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

# init_colors: populate color variables using tput when available
init_colors() {
  if [ -n "${NO_COLOR_FLAG:-}" ]; then
    NO_COLORS=1
    return
  fi
  if [ "${TERM:-}" = "dumb" ]; then
    NO_COLORS=1; return
  fi
  # tput may fail in some environments; guard it
  if command -v tput >/dev/null 2>&1; then
    local ncolors
    ncolors=$(tput colors 2>/dev/null || echo 0)
    if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
      RED=$(tput setaf 1)
      GREEN=$(tput setaf 2)
      YELLOW=$(tput setaf 3)
      BLUE=$(tput setaf 4)
      BOLD=$(tput bold)
      RESET=$(tput sgr0)
      NO_COLORS=0
      return
    fi
  fi
  NO_COLORS=1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    --no-color)
      NO_COLOR_FLAG=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      REQUESTED_TOOLS+=("$1")
      shift
      ;;
  esac
done

# Initialize color variables
init_colors

# Script name (dynamic) — use BASH_SOURCE when available, fallback to $0
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]:-$0}")"

# If --dry-run was passed and no tools were specified, make it preview all tools
if [ "$DRY_RUN" -eq 1 ] && [ ${#REQUESTED_TOOLS[@]} -eq 0 ]; then
  DRY_RUN_SHOW_ALL=1
fi

# Icons — only show when colors/icons are enabled
if [ "$NO_COLORS" -eq 0 ]; then
  ICON_OK=$'\xE2\x9C\x93'   # ✓
  ICON_FAIL=$'\xE2\x9D\x8C' # ❌
  ICON_DONE=$'\xE2\x9C\x85' # ✅
else
  ICON_OK=''
  ICON_FAIL=''
  ICON_DONE=''
fi

# If no arguments provided, show usage and exit
if [ ${#REQUESTED_TOOLS[@]} -eq 0 ]; then
  cat <<EOF
This script installs a curated set of CLI tools into your user-local bin directory
and adds it to your PATH in common shell rc files if needed.

Usage: ./${SCRIPT_NAME} [-v|--verbose] [--no-color] [tool1] [tool2] ... | all

Options:
  -v, --verbose   Show detailed installation progress
  --no-color      Disable colored output
  --dry-run       Show what would be installed without downloading or writing files

Available tools:
  atuin   - Magical shell history (atuinsh/atuin)
  bat     - A cat clone with wings (sharkdp/bat)
  btm     - A cross-platform graphical process/system monitor (ClementTsang/bottom)
  choose  - A simple interactive chooser (theryangeary/choose)
  curlie  - The power of curl, the ease of use of httpie (rs/curlie)
  delta   - A syntax-highlighting pager for git and diff output (dandavison/delta)
  duf     - Disk Usage/Free Utility (muesli/duf)
  dust    - A more intuitive version of du (bootandy/dust)
  eza     - A modern ls replacement (eza-community/eza)
  fd      - A simple, fast and user-friendly alternative to find (sharkdp/fd)
  fzf     - Command-line fuzzy finder (junegunn/fzf)
  gitui   - A fast terminal UI for git (gitui-org/gitui)
  hx      - A post-modern modal text editor (helix-editor/helix)
  hyperfine - A command-line benchmarking tool (sharkdp/hyperfine)
  jq      - Command-line JSON processor (jqlang/jq)
  lsd     - The next gen ls command (lsd-rs/lsd)
  lazydocker - A simple terminal UI for docker (jesseduffield/lazydocker)
  micro   - A modern and intuitive terminal-based text editor (zyedidia/micro)
  navi    - An interactive cheatsheet for commands (denisidoro/navi)
  nnn     - n³ The unorthodox terminal file manager (jarun/nnn)
  rg      - ripgrep, a line-oriented search tool (BurntSushi/ripgrep)
  rustnet - A small networking toolkit in Rust (domcyrus/rustnet)
  sad     - A simple and fast pager with syntax highlighting (ms-jpq/sad)
  sd      - Intuitive find & replace CLI (chmln/sd)
  termscp - A terminal SCP client with UI (veeso/termscp)
  tldr    - A fast tldr client (tealdeer-rs/tealdeer)
  xh      - A friendly and fast tool for making HTTP requests (ducaale/xh)
  zellij  - A terminal workspace (zellij-org/zellij)
  zoxide  - A smarter cd command (ajeetdsouza/zoxide)

Examples: 
  ./${SCRIPT_NAME} jq fzf bat
  ./${SCRIPT_NAME} --dry-run       # preview installing all available tools
  ./${SCRIPT_NAME} -v jq
EOF
  exit 0
fi

print_requested_tools() {
  # Join REQUESTED_TOOLS with ", " (respect IFS being set to \n\t earlier)
  local joined
  if [ ${#REQUESTED_TOOLS[@]} -eq 0 ]; then
    joined="none"
  else
    joined=$(printf '%s\n' "${REQUESTED_TOOLS[@]}" | paste -sd ', ' -)
  fi
  # Color tool names for readability
  if [ "$NO_COLORS" -eq 0 ]; then
    # color each item using tput-provided variables
    local colored
    colored=""
    for t in "${REQUESTED_TOOLS[@]}"; do
      if [ -z "$colored" ]; then
        colored="${BLUE}${t}${RESET}"
      else
        colored+=", ${BLUE}${t}${RESET}"
      fi
    done
    joined="$colored"
  fi
  log "Requested tools: ${joined}"
}

print_requested_tools

# ====================== Config / Defaults ======================
: "${XDG_BIN_HOME:=$HOME/.local/bin}"
INSTALL_DIR="$XDG_BIN_HOME"
mkdir -p "$INSTALL_DIR"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)
    ARCH_GREP='(x86_64|amd64|linux64)'
    ;;
  aarch64|arm64)
    ARCH_GREP='(aarch64|arm64)'
    ;;
  *) err "Unsupported architecture: $ARCH"; exit 1 ;;
esac

umask 022

# Check if a tool should be installed based on arguments
should_install() {
  local tool="$1"
  # If dry-run was requested with no explicit tools, treat it as requesting all
  if [ "$DRY_RUN_SHOW_ALL" -eq 1 ]; then
    return 0
  fi
  # Otherwise check if the specific tool was requested
  for requested in "${REQUESTED_TOOLS[@]}"; do
    if [ "$requested" = "$tool" ]; then
      return 0
    fi
  done
  return 1
}

downloader_name() {
  if have curl; then printf 'curl\n'
  elif have wget; then printf 'wget\n'
  else printf 'none\n'
  fi
}

fetch() {
  # fetch URL to output file; logs to stderr only
  local url="$1" out="$2"
  debug ""
  debug ">>> Fetching: $url"
  debug ">>> To file:  $out"
  debug ">>> Using:    $(downloader_name)"
  debug ""
  if have curl; then
    debug "+ curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 \"$url\" -o \"$out\""
    curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 15 "$url" -o "$out"
  elif have wget; then
    debug "+ wget -q --tries=3 --timeout=15 \"$url\" -O \"$out\""
    wget -q --tries=3 --timeout=15 "$url" -O "$out"
  else
    err "neither curl nor wget found."; return 1
  fi
}

add_path_export() {
  local line='export PATH="$HOME/.local/bin:$PATH"'
  local wrote=0
  for rc in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    if ! grep -qsF "$line" "$rc"; then
      printf '\n%s\n' "$line" >> "$rc"
      if [ "$NO_COLORS" -eq 0 ]; then
        log ">>> Added PATH export to ${GREEN}$rc${RESET}"
      else
        log ">>> Added PATH export to $rc"
      fi
      wrote=1
    fi
  done
  if [ $wrote -eq 0 ] && [ ! -f "$HOME/.profile" ]; then
    printf '%s\n' "$line" > "$HOME/.profile"
    if [ "$NO_COLORS" -eq 0 ]; then
      log ">>> Created ${GREEN}$HOME/.profile${RESET} with PATH export"
    else
      log ">>> Created $HOME/.profile with PATH export"
    fi
  fi
}

safe_tar_extract() {
  # Extract $1 into a temp dir; auto-detect compression (gz/xz/plain). stdout: dir
  local archive="$1"
  local tmpd
  tmpd="$(mktemp -d)" || { err "mktemp -d failed"; return 1; }
  debug ">>> Extracting $archive to $tmpd"
  if tar -tzf "$archive" >/dev/null 2>&1; then
    debug "+ tar -xzf \"$archive\" -C \"$tmpd\""
    tar -xzf "$archive" -C "$tmpd"
  elif tar -tJf "$archive" >/dev/null 2>&1; then
    debug "+ tar -xJf \"$archive\" -C \"$tmpd\""
    tar -xJf "$archive" -C "$tmpd"
  else
    debug "+ tar -xf \"$archive\" -C \"$tmpd\""
    tar -xf "$archive" -C "$tmpd"
  fi
  printf '%s\n' "$tmpd"
}

safe_zip_extract() {
  # Extract zip to a temp dir (requires unzip). stdout: dir
  local archive="$1"
  local tmpd
  tmpd="$(mktemp -d)" || { err "mktemp -d failed"; return 1; }
  debug ">>> Extracting zip $archive to $tmpd"
  if ! have unzip; then
    err "'unzip' not found but a .zip asset is required."; return 1
  fi
  unzip -q "$archive" -d "$tmpd"
  printf '%s\n' "$tmpd"
}

safe_deb_extract() {
  local archive="$1"
  local tmpd
  tmpd="$(mktemp -d)" || { err "mktemp -d failed"; return 1; }
  debug ">>> Extracting deb $archive to $tmpd"
  #     dpkg-deb -R "$tmpfile" > "$INSTALL_DIR/$bin"
  if ! have dpkg-deb; then
    err "'dpkg-deb' required to extract .deb files."; return 1
  fi
  dpkg-deb -R "$archive" "$tmpd"
  printf '%s\n' "$tmpd"
}

find_exe() {
  # Find first executable named $2 under $1; stdout: path
  local root="$1" name="$2"
  local found_path

  # handle special cases where the binary name differs from the expected
  # e.g. 'nnn' binary is named 'nnn-musl-static' in releases
  if [ "$name" = "nnn" ]; then
    name="nnn-musl-static"
  fi

  found_path="$(find "$root" -type f -name "$name" -perm /111 | head -n 1 || true)"
  if [ -z "${found_path:-}" ]; then
    err "executable '$name' not found under $root"
    return 1
  fi
  printf '%s\n' "$found_path"
}

gh_latest_asset_url() {
  # stdout: asset URL; args: owner repo name_regex [tag]
  local owner="$1" repo="$2" name_rx="$3" tag="${4:-latest}"
  local api="https://api.github.com/repos/${owner}/${repo}/releases/${tag}"
  local json
  if have curl; then json="$(curl -fsSL "$api" || true)"
  elif have wget; then json="$(wget -qO- "$api" || true)"
  else err "curl or wget required for GitHub API"; return 1
  fi

  local url
  # Collect browser_download_url values once and filter them rather than
  # repeating the extraction pipeline multiple times.
  local urls
  urls=$(printf '%s' "$json" \
    | grep '"browser_download_url":[^"]*"' \
    | sed -E 's/.*"browser_download_url":"([^"]*)".*/\1/' \
    | cut -d'"' -f4 || true)

  # detect tar.gz/xz first
  url=$(printf '%s\n' "$urls" \
    | grep -iE "$ARCH_GREP" \
    | grep -iE 'tar\.(gz|xz)$' \
    | grep -iE "$name_rx" \
    | head -n1 || true)

  # detect zip next
  if [ -z "$url" ]; then
    url=$(printf '%s\n' "$urls" \
      | grep -iE "$ARCH_GREP" \
      | grep -iE '\.zip$' \
      | grep -iE "$name_rx" \
      | head -n1 || true)
  fi

  # otherwise take any matching asset
  if [ -z "$url" ]; then
    url=$(printf '%s\n' "$urls" \
      | grep -iE "$ARCH_GREP" \
      | grep -iE "$name_rx" \
      | head -n1 || true)
  fi
  debug "attempting $url"
  # Expose the release tag/name (tag_name or name) for callers to use as a
  # version hint. This writes to a global variable API_RELEASE_TAG (intended
  # for immediate use by the caller) and returns the asset URL on stdout.
  local api_tag
  api_tag="$(printf '%s' "$json" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"\s*:\s*"([^"]+)".*/\1/' || true)"
  if [ -z "${api_tag:-}" ]; then
    api_tag="$(printf '%s' "$json" | grep -m1 '"name"' | sed -E 's/.*"name"\s*:\s*"([^"]+)".*/\1/' || true)"
  fi
  [ -n "$url" ] || return 1
  # Print URL< NUL >TAG< NUL > so callers can safely read both values using
  # mapfile -d '' or read -r -d '' constructs.
  printf '%s\0%s\0' "$url" "${api_tag:-}"
}

install_from_github() {
  # args: owner repo bin_name name_regex [tag]
  local owner="$1" repo="$2" bin="$3" rx="$4" tag="${5:-latest}"
  # If the user didn't request this tool (and didn't ask for 'all'), skip it.
  if ! should_install "$bin"; then
    debug "skipping $bin (not requested)"
    return 0
  fi
  # Print "Installing $bin..." without a trailing newline so we can append the
  # success mark on the same line when not verbose.
  # Use printf to avoid a newline and still send to stderr like log().
  # Print installing line with colored tool name when supported
  if [ "$NO_COLORS" -eq 0 ]; then
    printf 'Installing %b...' "${BOLD}${BLUE}${bin}${RESET}" >&2
  else
    printf 'Installing %s...' "$bin" >&2
  fi
  debug ""
  debug "=== Installing ${bin} (${owner}/${repo}${tag:+ @ $tag}) ==="
  local url api_tag arr
  # track temporary files/dirs created during this install so we can always
  # clean them up (even on early return). The RETURN trap runs when the
  # function returns.
  _inst_tmpfiles=()
  cleanup_install_from_github() { for p in "${_inst_tmpfiles[@]:-}"; do [ -n "$p" ] && rm -rf -- "$p" || true; done; }
  trap cleanup_install_from_github RETURN
  # gh_latest_asset_url prints URL and tag NUL-separated. Read both safely
  # into an array without using temporary files.
  if ! mapfile -d '' -t arr < <(gh_latest_asset_url "$owner" "$repo" "$rx" "$tag"); then
    err "could not resolve asset URL for ${owner}/${repo} ($bin)"; return 1
  fi
  url="${arr[0]:-}"
  api_tag="${arr[1]:-}"
  # If dry-run, report planned actions and skip download/install
  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] would fetch: $url"
    log "[dry-run] release tag: ${api_tag:-unknown}"
    local lower_preview
    lower_preview="$(printf '%s' "$url" | tr '[:upper:]' '[:lower:]')"
    if echo "$lower_preview" | grep -qE '\.tar\.(gz|xz)$'; then
      log "[dry-run] would extract ${GREEN}tar${RESET} and install $bin to $INSTALL_DIR/$bin"
    elif echo "$lower_preview" | grep -qE '\.zip$'; then
      log "[dry-run] would extract ${GREEN}zip${RESET} and install $bin to $INSTALL_DIR/$bin"
    elif echo "$lower_preview" | grep -qE '\.deb$'; then
      log "[dry-run] would extract ${GREEN}deb${RESET} and install $bin to $INSTALL_DIR/$bin"
    else
      log "[dry-run] would install ${YELLOW}binary${RESET} to $INSTALL_DIR/$bin"
    fi
    WOULD_INSTALL_TOOLS+=("$bin")
    if [ "$NO_COLORS" -eq 0 ]; then
      printf ' %b %b planned\n' "$ICON_OK" "${BLUE}${bin}${RESET}" >&2
    else
      printf ' %s %s planned\n' "$ICON_OK" "$bin" >&2
    fi
    return 0
  fi
  local tmpfile; tmpfile="$(mktemp)"
  _inst_tmpfiles+=("$tmpfile")
  fetch "$url" "$tmpfile"
  # Decide how to install based on extension
  local lower="$(printf '%s' "$url" | tr '[:upper:]' '[:lower:]')"
  local exdir= found=
  if echo "$lower" | grep -qE '\.tar\.(gz|xz)$'; then
    exdir="$(safe_tar_extract "$tmpfile")"
    _inst_tmpfiles+=("$exdir")
    found="$(find_exe "$exdir" "$bin")"
    install -D -m 0755 "$found" "$INSTALL_DIR/$bin"
  elif echo "$lower" | grep -qE '\.zip$'; then
    exdir="$(safe_zip_extract "$tmpfile")"
    _inst_tmpfiles+=("$exdir")
    found="$(find_exe "$exdir" "$bin")"
    install -D -m 0755 "$found" "$INSTALL_DIR/$bin"
  elif echo "$lower" | grep -qE '\.deb$'; then
    exdir="$(safe_deb_extract "$tmpfile")"
    _inst_tmpfiles+=("$exdir")
    found="$(find_exe "$exdir" "$bin")"
    install -D -m 0755 "$found" "$INSTALL_DIR/$bin"
  else
    # Treat as a plain binary asset
    debug ">>> Detected plain binary for $bin"
    install -D -m 0755 "$tmpfile" "$INSTALL_DIR/$bin"
  fi

  local ver='' tagver
  tagver="${api_tag:-}"
  if [ -n "${tagver:-}" ]; then
    # Try to extract a semver-like token from the tag (e.g. v1.2.3 or 1.2.3)
    ver=$(printf '%s' "$tagver" | grep -oE 'v?[0-9]+(\.[0-9]+){0,3}' | head -n1 || true)
  fi
  if [ -z "${ver:-}" ]; then
    # Fallback: probe the installed binary for its version (same as before)
    local out
    for flag in --version -V version -v; do
      out="$({ "$INSTALL_DIR/$bin" "$flag" 2>&1 || true; } | sed -n '1p' || true)"
      if [ -n "${out:-}" ]; then
        ver=$(printf '%s' "$out" | grep -oE 'v?[0-9]+(\.[0-9]+){0,3}' | head -n1 || true)
        [ -n "${ver:-}" ] && break
      fi
    done
  fi
    if [ -n "${ver:-}" ]; then
      if [ "$NO_COLORS" -eq 0 ]; then
        printf ' %b %b installed (%b)\n' "$ICON_OK" "${GREEN}${bin}${RESET}" "${YELLOW}${ver}${RESET}" >&2
      else
        printf ' %s %s installed (%s)\n' "$ICON_OK" "$bin" "$ver" >&2
      fi
    else
      if [ "$NO_COLORS" -eq 0 ]; then
        printf ' %b %b installed\n' "$ICON_OK" "${GREEN}${bin}${RESET}" >&2
      else
        printf ' %s %s installed\n' "$ICON_OK" "$bin" >&2
      fi
    fi

  INSTALLED_TOOLS+=("$bin")
}

# Track which tools were actually installed
INSTALLED_TOOLS=()
# Track which tools would be installed in a dry-run
WOULD_INSTALL_TOOLS=()

if [ "$NO_COLORS" -eq 0 ]; then
  log "Installing to: ${BOLD}${BLUE}$INSTALL_DIR${RESET}"
else
  log "Installing to: $INSTALL_DIR"
fi
add_path_export

# ====================== Tools List ======================
install_from_github "jqlang"       "jq"       "jq"      "jq[-_]linux.*${ARCH_GREP}"
install_from_github "junegunn"     "fzf"      "fzf"     "fzf.*linux_${ARCH_GREP}" 
install_from_github "atuinsh"      "atuin"    "atuin"   "atuin-${ARCH_GREP}-unknown-linux-musl"
install_from_github "tealdeer-rs"  "tealdeer" "tldr"    "tealdeer.*${ARCH_GREP}.*musl"
install_from_github "denisidoro"   "navi"     "navi"    "navi.*${ARCH_GREP}.*musl"
install_from_github "zellij-org"   "zellij"   "zellij"  "zellij.*${ARCH_GREP}.*linux-musl"
install_from_github "sharkdp"      "bat"      "bat"     "bat.*(musl|gnu|unknown-linux).*${ARCH_GREP}"
install_from_github "lsd-rs"       "lsd"      "lsd"     "lsd.*(musl|gnu|unknown-linux).*${ARCH_GREP}"
install_from_github "bootandy"     "dust"     "dust"    "du-dust.*${ARCH_GREP}"
install_from_github "sharkdp"      "hyperfine" "hyperfine" "hyperfine-musl.*${ARCH_GREP}"
install_from_github "muesli"       "duf"      "duf"     "duf.*linux.*${ARCH_GREP}"
install_from_github "ajeetdsouza"  "zoxide"   "zoxide"  "zoxide.*${ARCH_GREP}.*musl"
install_from_github "sharkdp"      "fd"       "fd"      "fd.*(musl|gnu|unknown-linux).*${ARCH_GREP}"
install_from_github "dandavison"   "delta"    "delta"   "delta.*${ARCH_GREP}.*musl"
install_from_github "theryangeary" "choose"   "choose"  "choose.*${ARCH_GREP}.*linux-musl"
install_from_github "ms-jpq"       "sad"      "sad"     "${ARCH_GREP}-unknown-linux-musl.deb"
install_from_github "chmln"        "sd"       "sd"      "sd.*${ARCH_GREP}.*unknown-linux-musl"
install_from_github "BurntSushi"   "ripgrep"  "rg"      "ripgrep.*${ARCH_GREP}.*musl"
install_from_github "domcyrus"     "rustnet"  "rustnet" "rustnet.*${ARCH_GREP}.*(musl|gnu|unknown-linux)" 
install_from_github "ClementTsang" "bottom"   "btm"     "bottom.*(musl|gnu|unknown-linux).*${ARCH_GREP}.deb"
install_from_github "jesseduffield" "lazydocker" "lazydocker" "lazydocker.*Linux.*${ARCH_GREP}"
install_from_github "rs"           "curlie"   "curlie"  "curlie.*freebsd.*${ARCH_GREP}"
install_from_github "ducaale"      "xh"       "xh"      "xh.*${ARCH_GREP}.*musl"
install_from_github "veeso"        "termscp"  "termscp" "termscp.*${ARCH_GREP}.*(musl|gnu|unknown-linux)" 
install_from_github "zyedidia"     "micro"    "micro"   "micro.*"
install_from_github "gitui-org"    "gitui"    "gitui"   "gitui.*${ARCH_GREP}"
install_from_github "jarun"        "nnn"      "nnn"     "nnn.*musl.*${ARCH_GREP}"
install_from_github "helix-editor" "helix"    "hx"      "helix.*${ARCH_GREP}"
install_from_github "eza-community" "eza"     "eza"     "eza.*${ARCH_GREP}.*musl"

# ====================== Done ======================
log ""
if [ "$DRY_RUN" -eq 1 ]; then
  if [ ${#WOULD_INSTALL_TOOLS[@]} -eq 0 ]; then
    log "No tools would be installed (none requested or all skipped)"
  else
    log "${ICON_DONE} Dry-run: would install ${#WOULD_INSTALL_TOOLS[@]} tool(s)"
  fi
else
  if [ ${#INSTALLED_TOOLS[@]} -eq 0 ]; then
    log "${ICON_FAIL} No tools were installed (none requested or all failed)"
    exit 1
  else
    log "${ICON_DONE} Done! Installed ${#INSTALLED_TOOLS[@]} tool(s)"
    log "If commands aren't found immediately, start a new shell or: source ~/.profile"
  fi
fi
