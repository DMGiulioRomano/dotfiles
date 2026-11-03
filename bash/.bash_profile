# ~/.bash_profile — login shell (macOS e alcuni Linux).
# Solo ciò che basta impostare una volta al login, il resto sta in .bashrc.
if command -v launchctl >/dev/null 2>&1; then
    launchctl setenv WEZTERM_CONFIG_FILE "$HOME/.config/wezterm/wezterm.lua"
fi
# Niente avviso "the default interactive shell is now zsh" di /bin/bash.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Sourca .bashrc per non duplicare la configurazione.
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"