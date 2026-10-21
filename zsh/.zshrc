# Alias condivisi (repo dotfiles/shell/.aliases → ~/.aliases)
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"

# Alias 'cat' solo se 'bat' è disponibile, altrimenti resta il cat di sistema.
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin${PATH:+:$PATH}";;
esac

autoload -Uz compinit && compinit
# Aggiunge le man page utente (~/.local/share/man) al MANPATH, se la
# directory esiste e non è già presente. Usa 'manpath' per non perdere
# i percorsi di sistema quando MANPATH non è ancora impostato.
if [ -d "$HOME/.local/share/man" ]; then
    case ":$MANPATH:" in
        *":$HOME/.local/share/man:"*) ;;  # già presente, non fare nulla
        *)
            if [ -z "${MANPATH:-}" ] && command -v manpath >/dev/null 2>&1; then
                export MANPATH="$HOME/.local/share/man:$(manpath)"
            else
                export MANPATH="$HOME/.local/share/man:${MANPATH:-}"
            fi
            ;;
    esac
fi