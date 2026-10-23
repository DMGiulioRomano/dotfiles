# Alias condivisi (repo dotfiles/shell/.aliases → ~/.aliases)
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"


case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin${PATH:+:$PATH}";;
esac

autoload -Uz compinit && compinit
# Includi i file nascosti (dotfile) nel completamento con Tab
_comp_options+=(globdots)

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

# 1. Configura il PATH per dare la precedenza ai binari Linux GNU di MacPorts
if [ -d "/opt/local/libexec/gnubin" ]; then
    # Carica ls, cp, mv, date, find, xargs ecc. in versione Linux
    export PATH="/opt/local/libexec/gnubin:$PATH"
fi
# Forza Vim a usare un TERM compatibile per aggiornare il titolo
vim() {
    TERM=xterm-256color command vim "$@"
}
# Forza Neovim a usare un TERM compatibile per il titolo
nvim() {
    TERM=xterm-256color command nvim "$@"
}
