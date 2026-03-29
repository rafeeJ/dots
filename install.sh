#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and make pipelines fail if any command fails.
set -euo pipefail

# ------------------------
# Utility helpers
# ------------------------
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m"

log()   { echo -e "${GREEN}==> ${NC}$1"; }
warn()  { echo -e "${YELLOW}Warning:${NC} $1"; }

# New: basic traps for nicer termination messages
trap 'echo -e "\n${YELLOW}Script aborted${NC}"' ERR
trap 'echo -e "\n${GREEN}Finished.${NC}"' EXIT

# New: platform + option handling
OS="$(uname)"
SKIP_BREW=0
SKIP_PLUGINS=0
UPDATE_ONLY=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  --no-brew        Skip Homebrew install / update
  --no-plugins     Skip Oh-My-Zsh plugin install / update
  --update-only    Only update what is already present, do not install missing pieces
  -h, --help       Show this help and exit
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-brew)      SKIP_BREW=1 ;;
      --no-plugins)   SKIP_PLUGINS=1 ;;
      --update-only)  UPDATE_ONLY=1 ;;
      -h|--help)      usage; exit 0 ;;
      *) warn "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

# ------------------------
# Installers / Updaters
# ------------------------
install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh already installed. Skipping."
  else
    log "Installing Oh My Zsh …"
    # Prevent the installer from switching shells or spawning zsh immediately after install.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed. Updating …"
  else
    log "Installing Homebrew … (non-interactive)"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Load Homebrew into the current shell session.
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  fi
  brew update --force --quiet
}

install_powerlevel10k() {
  local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ -d "$theme_dir" ]; then
    log "Powerlevel10k already installed. Pulling latest changes …"
    git -C "$theme_dir" pull --ff-only --quiet || warn "Failed to update Powerlevel10k"
  else
    log "Installing Powerlevel10k theme …"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
  fi
}

install_plugin() {
  # $1 -> repo url, $2 -> plugin directory name
  local repo="$1" plugin_name="$2"
  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"

  if [ -d "$plugin_dir" ]; then
    log "Plugin '$plugin_name' already installed. Updating …"
    git -C "$plugin_dir" pull --ff-only --quiet || warn "Failed to update $plugin_name"
  else
    log "Installing plugin '$plugin_name' …"
    git clone --depth=1 "$repo" "$plugin_dir"
  fi
}

install_zsh_plugins() {
  install_plugin https://github.com/lukechilds/zsh-nvm               zsh-nvm
  install_plugin https://github.com/zsh-users/zsh-autosuggestions     zsh-autosuggestions
  install_plugin https://github.com/zsh-users/zsh-history-substring-search zsh-history-substring-search
  install_plugin https://github.com/zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting
}

setup_dotfiles() {
  local repo_dir="$HOME/dev/dots"
  if [ -d "$repo_dir" ]; then
    log "Dotfiles repo already exists. Pulling latest changes …"
    git -C "$repo_dir" pull --rebase --quiet || warn "Failed to update dotfiles repo"
  else
    log "Cloning dotfiles repo …"
    mkdir -p "$(dirname "$repo_dir")"
    git clone https://github.com/rafeeJ/dots.git "$repo_dir"
  fi

  # Symlink (or update) dotfiles.
  log "Linking configuration files …"
  backup_if_needed "$HOME/.p10k.zsh"
  ln -sf "$repo_dir/.p10k.zsh" "$HOME/.p10k.zsh"

  # Link .zshrc from repo
  backup_if_needed "$HOME/.zshrc"
  ln -sf "$repo_dir/.zshrc" "$HOME/.zshrc"
}

# ------------------------
# Additional installers
# ------------------------
install_xcode_cli() {
  if [[ "$OS" == "Darwin" ]]; then
    if ! xcode-select -p >/dev/null 2>&1; then
      log "Installing Xcode Command Line Tools … (this may open a GUI prompt)"
      xcode-select --install || warn "Could not trigger Xcode CLT installer"
      # Wait for installation to complete (up to ~15 min)
      while ! xcode-select -p >/dev/null 2>&1; do sleep 30; done
    fi
  fi
}

install_fonts() {
  if (( SKIP_BREW )); then return; fi
  if [[ "$OS" == "Darwin" ]]; then
    if ! brew tap | grep -q "^homebrew/cask-fonts$"; then
      brew tap homebrew/cask-fonts
    fi
    if ! brew list --cask | grep -q "^font-meslo-lg-nerd-font$"; then
      log "Installing MesloLGS NF font …"
      brew install --cask font-meslo-lg-nerd-font
    fi
  fi
}

install_homebrew_packages() {
  if (( SKIP_BREW )); then return; fi
  local brewfile="$HOME/dev/dots/Brewfile"
  if [[ -f "$brewfile" ]]; then
    log "Installing bundle from Brewfile …"
    brew bundle --file="$brewfile" --no-lock || warn "brew bundle failed"
  fi
}

# ------------------------
# Git configuration
# ------------------------
configure_git() {
  local desired_name="Rafee Jenkins"
  local desired_email="rafeejenkins@gmail.com"
  local current_name="$(git config --global --get user.name || true)"
  local current_email="$(git config --global --get user.email || true)"

  if [[ "$current_name" != "$desired_name" ]]; then
    log "Setting global git user.name to '$desired_name'"
    git config --global user.name "$desired_name"
  fi
  if [[ "$current_email" != "$desired_email" ]]; then
    log "Setting global git user.email to '$desired_email'"
    git config --global user.email "$desired_email"
  fi

  # Ensure push.autoSetupRemote is enabled so 'git push' auto creates upstreams.
  if ! git config --global --get push.autoSetupRemote >/dev/null 2>&1; then
    log "Enabling git push.autoSetupRemote"
    git config --global --add --bool push.autoSetupRemote true
  fi
}

# ------------------------
# Powerlevel10k + .zshrc configuration
# ------------------------
configure_p10k() {
  local zshrc="$HOME/.zshrc"
  # If ~/.zshrc is a symlink (managed by dotfiles repo), assume it already contains required settings.
  if [[ -L "$zshrc" ]]; then
    log "~/.zshrc is symlinked; skipping automatic Powerlevel10k configuration."
    return
  fi

  # Ensure .zshrc exists
  if [[ ! -f "$zshrc" ]]; then
    warn "~/.zshrc not found; creating a minimal one."
    echo "export ZSH=\"$HOME/.oh-my-zsh\"" > "$zshrc"
    echo "source \"$HOME/.oh-my-zsh/oh-my-zsh.sh\"" >> "$zshrc"
  fi

  backup_if_needed "$zshrc"

  # Set Powerlevel10k theme
  if grep -q '^ZSH_THEME=' "$zshrc"; then
    if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$zshrc"; then
      log "Updating ZSH_THEME to Powerlevel10k in .zshrc"
      # macOS compatible sed in-place
      sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
    fi
  else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$zshrc"
  fi

  # Source .p10k.zsh if not already
  if ! grep -q 'source .*\.p10k\.zsh' "$zshrc"; then
    log "Adding .p10k.zsh sourcing to .zshrc"
    { echo ''; echo '# Load Powerlevel10k configuration'; echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh'; } >> "$zshrc"
  fi

  # Ensure desired plugins are enabled
  local desired_plugins="git zsh-nvm zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting"
  if grep -q '^plugins=' "$zshrc"; then
    # Replace the line entirely to guarantee ordering and presence
    log "Updating Oh My Zsh plugins list"
    sed -i '' "s/^plugins=.*/plugins=(${desired_plugins})/" "$zshrc"
  else
    echo "plugins=(${desired_plugins})" >> "$zshrc"
  fi
}

# ------------------------
# Main
# ------------------------
main() {
  # Execute the parsed options
  if [[ "$OS" == "Darwin" ]]; then install_xcode_cli; fi

  (( SKIP_BREW )) || install_homebrew
  install_oh_my_zsh
  (( SKIP_BREW )) || install_fonts

  configure_git
  configure_p10k
  install_powerlevel10k
  (( SKIP_PLUGINS )) || install_zsh_plugins

  setup_dotfiles
  (( SKIP_BREW )) || install_homebrew_packages

  log "Setup complete! Open a new Zsh session or run 'exec zsh' to apply the changes."
}

# First parse CLI flags, then run main
parse_args "$@"
main
