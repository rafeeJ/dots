if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export NVM_AUTO_USE=true
export NODE_EXTRA_CA_CERTS=~/lbg-root-prod-ca.crt 
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  emoji
  ssh-agent
  git
  z
  zsh-nvm
  iterm2
  colored-man-pages
  yarn
  vscode
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
  npm
)
source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.bin:$PATH"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# recommended by brew doctor
export PATH="/usr/local/bin:$PATH"
# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
eval "$(rbenv init - --no-rehash)"
