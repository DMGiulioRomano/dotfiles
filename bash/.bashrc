# ~/.bashrc — bash interattivo.
# Se non interattivo, esci subito (evita effetti su script/cron).
case $- in
    *i*) ;;
    *) return 0 ;;
esac

# Alias condivisi (repo dotfiles/shell/.aliases → ~/.aliases)
[ -f "$HOME/.aliases" ] && . "$HOME/.aliases"

# PATH: ~/.local/bin se non già presente.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin${PATH:+:$PATH}";;
esac

# MANPATH per le man page utente.
if [ -d "$HOME/.local/share/man" ]; then
    case ":$MANPATH:" in
        *":$HOME/.local/share/man:"*) ;;
        *)
            if [ -z "${MANPATH:-}" ] && command -v manpath >/dev/null 2>&1; then
                export MANPATH="$HOME/.local/share/man:$(manpath)"
            else
                export MANPATH="$HOME/.local/share/man:${MANPATH:-}"
            fi
            ;;
    esac
fi

# History
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend