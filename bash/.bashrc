# ~/.bashrc — bash, al pari di ~/.zprofile + ~/.zshrc.

# PATH dei gestori di pacchetti. Sta prima del controllo qui sotto perché serve
# anche a 'bash -lc comando', e prima di .aliases, che cerca bat nel PATH.
for _dir in /opt/local/sbin /opt/local/bin; do
    [ -d "$_dir" ] || continue
    case ":$PATH:" in
        *":$_dir:"*) ;;
        *) export PATH="$_dir:$PATH";;
    esac
done
unset _dir

# Homebrew, se presente: /opt/homebrew su Apple Silicon, /usr/local su Intel.
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
    for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$_brew" ]; then
            eval "$("$_brew" shellenv)"
            break
        fi
    done
    unset _brew
fi

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

# Precedenza ai binari GNU di MacPorts e di Homebrew (ls, find, grep, sed, make…).
for _dir in /opt/local/libexec/gnubin \
    {/opt/homebrew,/usr/local}/opt/{coreutils,findutils,grep,gnu-sed,make}/libexec/gnubin; do
    [ -d "$_dir" ] || continue
    case ":$PATH:" in
        *":$_dir:"*) ;;
        *) export PATH="$_dir:$PATH";;
    esac
done
unset _dir

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

# Prompt uguale a quello predefinito di zsh: utente@host cartella $
PS1='\u@\h \W \$ '

# Completamento con Tab, l'equivalente di compinit in .zshrc.
# Il pacchetto bash-completion (in tools.txt) richiede bash 4 o superiore.
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    for _file in /opt/local/etc/profile.d/bash_completion.sh \
        /opt/homebrew/etc/profile.d/bash_completion.sh \
        /usr/local/etc/profile.d/bash_completion.sh \
        /etc/profile.d/bash_completion.sh; do
        if [ -r "$_file" ]; then
            # shellcheck disable=SC1090
            . "$_file"
            break
        fi
    done
    unset _file
fi

# Completamento di git, compresi gli alias di .aliases (zsh li risolve da solo).
if [ -r /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash ]; then
    . /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
    __git_complete gs _git_status
    __git_complete ga _git_add
    __git_complete gc _git_commit
    __git_complete gp _git_push
    __git_complete gl _git_log
    __git_complete gd _git_diff
    __git_complete gb _git_branch
fi

# Tab come in zsh: il primo elenca le alternative, i successivi le scorrono.
if [ -t 0 ]; then
    bind 'set show-all-if-ambiguous on'
    bind 'set menu-complete-display-prefix on'
    bind 'TAB:menu-complete'
fi

# Forza Vim a usare un TERM compatibile per aggiornare il titolo
vim() {
    TERM=xterm-256color command vim "$@"
}
# Forza Neovim a usare un TERM compatibile per il titolo
nvim() {
    TERM=xterm-256color command nvim "$@"
}

# History
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend