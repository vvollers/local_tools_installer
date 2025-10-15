# Local Tools Installer

A curated collection of modern CLI tools installer script that downloads and installs high-quality command-line utilities directly from GitHub releases into your user-local bin directory (`~/.local/bin`).

## What It Does

This script automatically:

- Downloads the latest releases of popular CLI tools from GitHub
- Installs them to `~/.local/bin` (or `$XDG_BIN_HOME` if set)
- Adds the bin directory to your PATH in common shell rc files
- Supports both x86_64 and aarch64/arm64 architectures
- Handles various archive formats (tar.gz, tar.xz, zip, deb)

## Requirements

- Linux system with bash
- `curl` or `wget` for downloading
- `tar` for extracting archives
- `unzip` for zip files (if needed)
- `dpkg-deb` for .deb packages (if needed)

## Available Tools

| Tool           | Description                                          | Repository                                                              |
| -------------- | ---------------------------------------------------- | ----------------------------------------------------------------------- |
| **atuin**      | Magical shell history                                | [atuinsh/atuin](https://github.com/atuinsh/atuin)                       |
| **bat**        | A cat clone with wings                               | [sharkdp/bat](https://github.com/sharkdp/bat)                           |
| **btm**        | A cross-platform graphical process/system monitor    | [ClementTsang/bottom](https://github.com/ClementTsang/bottom)           |
| **choose**     | A simple interactive chooser                         | [theryangeary/choose](https://github.com/theryangeary/choose)           |
| **curlie**     | The power of curl, the ease of use of httpie         | [rs/curlie](https://github.com/rs/curlie)                               |
| **delta**      | A syntax-highlighting pager for git and diff output  | [dandavison/delta](https://github.com/dandavison/delta)                 |
| **duf**        | Disk Usage/Free Utility                              | [muesli/duf](https://github.com/muesli/duf)                             |
| **dust**       | A more intuitive version of du                       | [bootandy/dust](https://github.com/bootandy/dust)                       |
| **eza**        | A modern ls replacement                              | [eza-community/eza](https://github.com/eza-community/eza)               |
| **fd**         | A simple, fast and user-friendly alternative to find | [sharkdp/fd](https://github.com/sharkdp/fd)                             |
| **fzf**        | Command-line fuzzy finder                            | [junegunn/fzf](https://github.com/junegunn/fzf)                         |
| **gitui**      | A fast terminal UI for git                           | [gitui-org/gitui](https://github.com/gitui-org/gitui)                   |
| **hx**         | A post-modern modal text editor                      | [helix-editor/helix](https://github.com/helix-editor/helix)             |
| **hyperfine**  | A command-line benchmarking tool                     | [sharkdp/hyperfine](https://github.com/sharkdp/hyperfine)               |
| **jq**         | Command-line JSON processor                          | [jqlang/jq](https://github.com/jqlang/jq)                               |
| **lazydocker** | A simple terminal UI for docker                      | [jesseduffield/lazydocker](https://github.com/jesseduffield/lazydocker) |
| **lsd**        | The next gen ls command                              | [lsd-rs/lsd](https://github.com/lsd-rs/lsd)                             |
| **micro**      | A modern and intuitive terminal-based text editor    | [zyedidia/micro](https://github.com/zyedidia/micro)                     |
| **navi**       | An interactive cheatsheet for commands               | [denisidoro/navi](https://github.com/denisidoro/navi)                   |
| **nnn**        | n³ The unorthodox terminal file manager              | [jarun/nnn](https://github.com/jarun/nnn)                               |
| **rg**         | ripgrep, a line-oriented search tool                 | [BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)             |
| **rustnet**    | A small networking toolkit in Rust                   | [domcyrus/rustnet](https://github.com/domcyrus/rustnet)                 |
| **sad**        | A simple and fast pager with syntax highlighting     | [ms-jpq/sad](https://github.com/ms-jpq/sad)                             |
| **sd**         | Intuitive find & replace CLI                         | [chmln/sd](https://github.com/chmln/sd)                                 |
| **termscp**    | A terminal SCP client with UI                        | [veeso/termscp](https://github.com/veeso/termscp)                       |
| **tldr**       | A fast tldr client                                   | [tealdeer-rs/tealdeer](https://github.com/tealdeer-rs/tealdeer)         |
| **xh**         | A friendly and fast tool for making HTTP requests    | [ducaale/xh](https://github.com/ducaale/xh)                             |
| **zellij**     | A terminal workspace                                 | [zellij-org/zellij](https://github.com/zellij-org/zellij)               |
| **zoxide**     | A smarter cd command                                 | [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)             |

## Usage

### Basic Usage

```bash
# Show help and available tools
./local_tools_installer.sh

# Install specific tools
./local_tools_installer.sh jq fzf bat

# Install with verbose output
./local_tools_installer.sh -v jq fzf

# Preview what would be installed (dry run)
./local_tools_installer.sh --dry-run jq fzf

# Preview all available tools
./local_tools_installer.sh --dry-run

# Disable colored output
./local_tools_installer.sh --no-color jq fzf
```

### Options

- `-v, --verbose` - Show detailed installation progress
- `--no-color` - Disable colored output
- `--dry-run` - Show what would be installed without downloading or writing files

### Run Directly from GitHub

You can run this script directly from GitHub without downloading it first:

```bash
# Install specific tools
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/local_tools_installer.sh | bash -s -- jq fzf bat

# Or with wget
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/local_tools_installer.sh | bash -s -- jq fzf bat

# Preview what would be installed
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/local_tools_installer.sh | bash -s -- --dry-run

# Install with verbose output
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/local_tools_installer.sh | bash -s -- -v jq fzf bat
```

## Examples

```bash
# Install essential development tools
./local_tools_installer.sh jq fzf bat rg fd

# Install file management tools
./local_tools_installer.sh eza lsd dust duf nnn

# Install git-related tools
./local_tools_installer.sh delta gitui

# Install text editors
./local_tools_installer.sh hx micro

# Install system monitoring tools
./local_tools_installer.sh btm lazydocker

# Preview all available tools before installing
./local_tools_installer.sh --dry-run
```

## Installation Directory

Tools are installed to:

- `~/.local/bin` (default)
- Or `$XDG_BIN_HOME` if the environment variable is set

The script automatically adds this directory to your PATH by modifying:

- `~/.profile`
- `~/.bashrc` (if it exists)
- `~/.zshrc` (if it exists)

## After Installation

After running the script, you may need to:

1. Start a new shell session, or
2. Run `source ~/.profile` to update your current session's PATH

## Architecture Support

The script supports:

- **x86_64** / **amd64** architectures
- **aarch64** / **arm64** architectures

It automatically detects your system architecture and downloads the appropriate binaries.

## Error Handling

The script includes robust error handling:

- Validates downloads before extraction
- Cleans up temporary files automatically
- Provides clear error messages
- Supports retry mechanisms for network operations

## License

This script is provided as-is. Individual tools have their own licenses - please check each tool's repository for license information.
