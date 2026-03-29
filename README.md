# dots

Personal dotfiles and machine setup for macOS.

## What it does

Running `install.sh` will set up a new machine with:

- **Xcode Command Line Tools** (macOS only)
- **Homebrew** — installed and updated
- **Oh My Zsh** — installed with plugins:
  - `zsh-nvm`, `zsh-autosuggestions`, `zsh-history-substring-search`, `zsh-syntax-highlighting`
- **Powerlevel10k** theme
- **MesloLGS NF** font (required for Powerlevel10k icons)
- **Homebrew packages** from `Brewfile` (if present)
- **Dotfiles** — clones this repo to `~/dev/dots` and symlinks `.zshrc` and `.p10k.zsh`
- **Git config** — sets global `user.name`, `user.email`, and `push.autoSetupRemote`

## Usage

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/rafeeJ/dots/main/install.sh)
```

Or if you've already cloned the repo:

```bash
./install.sh
```

### Options

| Flag | Description |
|------|-------------|
| `--no-brew` | Skip Homebrew install/update and all brew-dependent steps |
| `--no-plugins` | Skip Oh My Zsh plugin install/update |
| `--update-only` | Only update already-installed components, skip missing ones |
| `-h, --help` | Show usage and exit |

### Examples

```bash
# Full setup
./install.sh

# Skip Homebrew (e.g. on a machine where brew is managed separately)
./install.sh --no-brew

# Just update existing installs
./install.sh --update-only
```

## After running

Open a new terminal session or run `exec zsh` to apply all changes.

If Powerlevel10k prompts you for configuration on first launch, follow the wizard or let it use the existing `.p10k.zsh` from this repo.
