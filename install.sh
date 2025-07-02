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
  ln -sf "$repo_dir/.p10k.zsh" "$HOME/.p10k.zsh"
}

# ------------------------
# Main
# ------------------------
main() {
  install_oh_my_zsh
  install_homebrew
  install_powerlevel10k
  install_zsh_plugins
  setup_dotfiles

  log "Setup complete! Open a new Zsh session or run 'exec zsh' to apply the changes."
}

main "$@"
