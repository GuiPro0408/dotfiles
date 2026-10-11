# Make mise-managed Node/Python/Ruby available to non-interactive zsh shells
# (scripts, IDEs, agents). Interactive shells run `mise activate` from ~/.zshrc,
# which takes precedence over these shims.
# Keep this file lightweight: .zshenv is loaded by every zsh invocation.
case ":$PATH:" in
  *":$HOME/.local/share/mise/shims:"*) ;;
  *) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
esac
