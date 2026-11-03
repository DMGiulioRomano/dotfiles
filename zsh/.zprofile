# MacPorts Installer addition on 2026-10-20_at_10:27:24: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.
# Homebrew, se presente: /opt/homebrew su Apple Silicon, /usr/local su Intel.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$_brew" ]; then
        eval "$("$_brew" shellenv)"
        break
    fi
done
unset _brew
launchctl setenv WEZTERM_CONFIG_FILE "$HOME/.config/wezterm/wezterm.lua"
