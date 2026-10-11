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

export PATH="${HOME}/.cargo/bin:${PATH}:/usr/local/sbin"

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
# mise — Node, Python and Ruby versions (replaces nvm / pyenv / rbenv)
# Global defaults: ~/.config/mise/config.toml. Per project: mise.toml or the
# existing .nvmrc / .python-version / .ruby-version files.
# Non-interactive shells get the shims from ~/.zshenv instead.
# ──────────────────────────────────────────────────────────────
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# Python version in RPROMPT (refreshed on directory change only)
autoload -U add-zsh-hook
_python_prompt_update() {
  local ver="$(mise current python 2>/dev/null)"
  RPROMPT="[🐍 ${ver%% *}]"
}
add-zsh-hook chpwd _python_prompt_update
_python_prompt_update

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

  printf "\n${bold}${green}📦 Versions${reset}  ${dim}(mise — Node, Python, Ruby)${reset}\n"
  printf "  ${cyan}mise ls${reset}           Installed versions + where each is set\n"
  printf "  ${cyan}mise use node@22${reset}  Pin a version in the current project\n"
  printf "  ${cyan}mise install${reset}      Install what the project asks for\n"

  printf "\n${dim}Run ${cyan}tools${dim} anytime to see this again.${reset}\n\n"
}

# Machine-local / private config (e.g. work-specific helpers), not versioned here.
# ~/.config/shell/*.sh is shared with bash; ~/.config/zsh/*.zsh is zsh-only.
for _zsh_local in ~/.config/shell/*.sh(N) ~/.config/zsh/*.zsh(N); do source "$_zsh_local"; done
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
