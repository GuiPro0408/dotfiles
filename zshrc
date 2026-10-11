ZSH=$HOME/.oh-my-zsh

# You can change the theme with another one from https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Useful oh-my-zsh plugins for Le Wagon bootcamps
plugins=(git gitfast last-working-dir common-aliases zsh-syntax-highlighting history-substring-search ssh-agent)

# Disable warning about insecure completion-dependent directories
ZSH_DISABLE_COMPFIX=true

# Actually load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm # No interactive rm by default (brought by plugins/common-aliases)
unalias lt # we need `lt` for https://github.com/localtunnel/localtunnel

# ──────────────────────────────────────────────────────────────
# PATH — consolidated & deduplicated
# ──────────────────────────────────────────────────────────────
typeset -U path PATH  # auto-deduplicate PATH entries

export PATH="${HOME}/.cargo/bin:${HOME}/.rbenv/bin:${PATH}:/usr/local/sbin"

# Windows paths (only the ones actually needed — appendWindowsPath=false in wsl.conf)
# VS Code remote CLI, Chrome (for $BROWSER), Docker CLI
for _wpath in \
  "/mnt/c/Users/guill/AppData/Local/Programs/Microsoft VS Code/bin" \
  "/mnt/c/Program Files/Google/Chrome/Application" \
  "/mnt/c/Program Files/Docker/Docker/resources/bin"; do
  [[ -d "$_wpath" ]] && path+=("$_wpath")
done
unset _wpath

# ──────────────────────────────────────────────────────────────
# Lazy-load rbenv (deferred eval on first use)
# ──────────────────────────────────────────────────────────────
_lazy_rbenv_init() {
  unfunction ruby gem irb bundle rake rbenv 2>/dev/null
  eval "$(rbenv init -)"
}
if type rbenv &>/dev/null; then
  for _cmd in ruby gem irb bundle rake rbenv; do
    eval "${_cmd}() { _lazy_rbenv_init; ${_cmd} \"\$@\" }"
  done
  unset _cmd
fi

# ──────────────────────────────────────────────────────────────
# Lazy-load pyenv (shell integration only — shims PATH set in .zprofile)
# ──────────────────────────────────────────────────────────────
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

_lazy_pyenv_init() {
  unfunction pyenv 2>/dev/null
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init - 2>/dev/null)"
}
if type pyenv &>/dev/null; then
  pyenv() { _lazy_pyenv_init; pyenv "$@" }
fi

# Cached pyenv version in RPROMPT (only updates on directory change)
_pyenv_version_cache=""
_pyenv_prompt_update() {
  local ver
  if [[ -f .python-version ]]; then
    ver="$(cat .python-version)"
  elif [[ -n "$PYENV_VERSION" ]]; then
    ver="$PYENV_VERSION"
  else
    ver="${_pyenv_version_cache:-system}"
    [[ -z "$_pyenv_version_cache" ]] && _pyenv_version_cache="$(pyenv version-name 2>/dev/null || echo system)"
    ver="$_pyenv_version_cache"
  fi
  RPROMPT="[🐍 $ver]"
}
_pyenv_chpwd_update() {
  _pyenv_version_cache=""  # invalidate cache on cd
  _pyenv_prompt_update
}
autoload -U add-zsh-hook
add-zsh-hook chpwd _pyenv_chpwd_update
add-zsh-hook precmd _pyenv_prompt_update

# ──────────────────────────────────────────────────────────────
# Lazy-load nvm (biggest win — defers ~400ms of startup)
# ──────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"

_lazy_nvm_init() {
  unfunction nvm node npm npx yarn corepack 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # Add nvm default node to PATH immediately (fast, no nvm source)
  _nvm_default_dir="$NVM_DIR/alias/default"
  if [ -s "$_nvm_default_dir" ]; then
    _nvm_default_ver="$(cat "$_nvm_default_dir")"
    # Resolve to actual path — handles partial versions like "20"
    _nvm_node_dir="$NVM_DIR/versions/node"
    for _d in "$_nvm_node_dir"/v${_nvm_default_ver}*; do
      [ -d "$_d/bin" ] && path=("$_d/bin" $path) && break
    done
    unset _nvm_default_ver _nvm_node_dir _d
  fi
  unset _nvm_default_dir

  # Stub functions — load nvm on first use
  for _cmd in nvm node npm npx yarn corepack; do
    eval "${_cmd}() { _lazy_nvm_init; ${_cmd} \"\$@\" }"
  done
  unset _cmd

  # Auto-switch on cd into directories with .nvmrc
  load-nvmrc() {
    local nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"
    if [ -n "$nvmrc_path" ]; then
      _lazy_nvm_init  # ensure nvm is loaded
      local node_version="$(nvm version)"
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use --silent
      fi
    fi
  }
  add-zsh-hook chpwd load-nvmrc
fi

# ──────────────────────────────────────────────────────────────
# Aliases & environment
# ──────────────────────────────────────────────────────────────
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export BUNDLER_EDITOR=code
export EDITOR=code

# Set ipdb as the default Python debugger
export PYTHONBREAKPOINT=ipdb.set_trace

# Browser (Windows Chrome via WSL)
export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
export GH_BROWSER="$BROWSER"

# direnv
eval "$(direnv hook zsh)"

# PHP : un seul, /usr/bin/php -> php8.3 (apt, PPA ondrej) via update-alternatives.
# Ni alias ni wrapper : interactif, make, hooks et Composer voient le meme binaire,
# les memes extensions et le meme short_open_tag (On, via
# /etc/php/8.3/cli/conf.d/99-local.ini).

# Source uv/rye env if present
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ──────────────────────────────────────────────────────────────
# Modern CLI tool integrations
# ──────────────────────────────────────────────────────────────

# fzf — fuzzy finder (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
# Use fd for fzf file search if available
command -v fdfind &>/dev/null && export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
command -v fdfind &>/dev/null && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
command -v fdfind &>/dev/null && export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'

# zoxide — smart cd (use `z` instead of `cd`)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# eza — modern ls replacement
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first --git'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
fi

# bat — cat with syntax highlighting (Ubuntu names it batcat)
if command -v batcat &>/dev/null; then
  alias bat='batcat'
  alias cat='batcat --paging=never'
fi

# fd — fast find (Ubuntu names it fdfind)
command -v fdfind &>/dev/null && alias fd='fdfind'

# ── Welcome / Tool Helper ────────────────────────────────────────────
# Shows available developer tools on interactive shell start.
# Run `tools` anytime to display again.
function tools() {
  local cyan='\033[0;36m' green='\033[0;32m' yellow='\033[0;33m'
  local dim='\033[2m' bold='\033[1m' reset='\033[0m'

  printf "\n${bold}${cyan}⚡ Developer Toolbox${reset}\n"
  printf "${dim}─────────────────────────────────────────────${reset}\n"

  printf "\n${bold}${green}🔍 Search & Navigation${reset}\n"
  printf "  ${cyan}Ctrl+R${reset}   Fuzzy search command history  ${dim}(fzf)${reset}\n"
  printf "  ${cyan}Ctrl+T${reset}   Fuzzy find files               ${dim}(fzf + fd)${reset}\n"
  printf "  ${cyan}Alt+C${reset}    Fuzzy cd into directories       ${dim}(fzf + fd)${reset}\n"
  printf "  ${cyan}z <dir>${reset}  Smart cd with frecency          ${dim}(zoxide)${reset}\n"
  printf "  ${cyan}fd${reset}       Fast file finder                ${dim}(fd-find)${reset}\n"

  printf "\n${bold}${green}📁 Files & Output${reset}\n"
  printf "  ${cyan}ls${reset}       Colored file listing            ${dim}(eza)${reset}\n"
  printf "  ${cyan}ll${reset}       Detailed listing with git info  ${dim}(eza -lah --git)${reset}\n"
  printf "  ${cyan}lt${reset}       Tree view (2 levels)            ${dim}(eza --tree)${reset}\n"
  printf "  ${cyan}cat${reset}      Syntax-highlighted output       ${dim}(bat)${reset}\n"

  printf "\n${bold}${green}🔧 Git${reset}\n"
  printf "  ${cyan}lg${reset}       Pretty log graph                ${dim}(git lg)${reset}\n"
  printf "  ${cyan}lazygit${reset}  Terminal UI for git             ${dim}(lazygit)${reset}\n"
  printf "  ${cyan}amend${reset}    Amend last commit               ${dim}(git amend)${reset}\n"
  printf "  ${cyan}undo${reset}     Undo last commit (keep changes) ${dim}(git undo)${reset}\n"
  printf "  ${cyan}wip${reset}      Quick WIP commit                ${dim}(git wip)${reset}\n"
  printf "  ${cyan}sweep${reset}    Clean merged branches           ${dim}(git sweep)${reset}\n"
  printf "  ${dim}  + delta pager · fsmonitor · rerere · maintenance${reset}\n"

  printf "\n${bold}${green}⚙️  System${reset}\n"
  printf "  ${cyan}htop${reset}     Interactive process viewer\n"
  printf "  ${cyan}myip${reset}     Show public IP address\n"
  printf "  ${cyan}serve${reset}    Python HTTP server (cwd)\n"
  printf "  ${cyan}stt${reset}      Open current dir in VS Code\n"

  printf "\n${bold}${green}📌 Common commands${reset}\n"
  printf "  ${cyan}mkcd <dir>${reset}  mkdir + cd in one step\n"

  # Sections contributed by ~/.config/zsh/*.zsh
  (( $+functions[tools_local] )) && tools_local

  printf "\n${bold}${green}🖥️  Claude Desktop${reset}  ${dim}(WSLg: les 2 flags sont obligatoires)${reset}\n"
  printf "  ${cyan}cdesk${reset}       Lancer l'app (keyring + WebGL OK), détachée\n"
  printf "  ${cyan}cdesk-code${reset}  Ouvrir une nouvelle session Claude Code\n"
  printf "  ${cyan}cdesk-stop${reset}  Arrêter proprement (SIGTERM, garde la géométrie)\n"
  printf "  ${cyan}wclip${reset}       Capture Windows -> PNG dans ~/.claude/clips\n"
  printf "  ${cyan}wclip -x${reset}    Republier la capture sur X11 (si le service est arrêté)\n"

  printf "\n${bold}${green}📦 Version Managers${reset}  ${dim}(lazy-loaded on first use)${reset}\n"
  printf "  ${cyan}nvm${reset}      Node.js version manager\n"
  printf "  ${cyan}pyenv${reset}    Python version manager\n"
  printf "  ${cyan}rbenv${reset}    Ruby version manager\n"

  printf "\n${dim}Run ${cyan}tools${dim} anytime to see this again.${reset}\n\n"
}

# Machine-local / private config (e.g. work-specific helpers), not versioned here.
for _zsh_local in ~/.config/zsh/*.zsh(N); do source "$_zsh_local"; done
unset _zsh_local

# Show tools on interactive shell startup (not in scripts or sub-shells)
if [[ -o interactive && -z "$TOOLS_SHOWN" ]]; then
  export TOOLS_SHOWN=1
  tools
fi

# bun completions
[ -s "/home/guillaume/.bun/_bun" ] && source "/home/guillaume/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
