#!/usr/bin/env bash
# install.sh — attiva (o disattiva) tutti i pacchetti Stow del repo.
#
# Uso:
#   ./install.sh              # stow di tutti i pacchetti (--no-folding)
#   ./install.sh -D           # unstow di tutti i pacchetti
#   ./install.sh -n           # dry-run: mostra cosa farebbe
#   ./install.sh -t DIR       # target diverso da $HOME
#   ./install.sh nvim zsh     # stow solo dei pacchetti indicati
#   ./install.sh -h           # aiuto
#
# Licenza: MIT
set -euo pipefail

# Le glob non trovate vengono espanse a stringa vuota (anziché lasciate
# letterali): evita di passare "*" come "pacchetto" a stow se il repo
# non contiene sottodirectory.
shopt -s nullglob

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"
MODE="stow"          # stow | unstow
DRY_RUN=0
EXPLICIT_PKGS=()

# Directory che non sono pacchetti (escluse sempre dalla scansione automatica).
# Aggiungi qui eventuali cartelle "di servizio" del repo.
EXCLUDE_DIRS=(
    .git
    .github
    scripts
)

# ============================================================
# DEFINIZIONE DELLE FUNZIONI (prima di essere usate)
# ============================================================

usage() {
    cat <<EOF
Uso: $(basename "$0") [opzioni] [pacchetto...]

Attiva (o disattiva) i pacchetti Stow presenti in: $REPO_ROOT
Target: $TARGET

Opzioni:
  -D, --delete        Disattiva i pacchetti (stow -D) invece di attivarli
  -n, --dry-run       Mostra i comandi senza eseguirli
  -t, --target DIR    Directory di destinazione (default: \$HOME)
  -h, --help          Mostra questo aiuto

Senza argomenti pacchetto, lo script usa tutte le directory di primo livello
del repo (escluse: ${EXCLUDE_DIRS[*]}).

Esempi:
  ./install.sh                    # stow di tutti i pacchetti
  ./install.sh -D                 # unstow di tutti i pacchetti
  ./install.sh nvim zsh           # stow solo di nvim e zsh
  ./install.sh -n                 # dry-run su tutti
EOF
}

is_excluded() {
    local name="$1" ex
    for ex in "${EXCLUDE_DIRS[@]}"; do
        [[ "$name" == "$ex" ]] && return 0
    done
    return 1
}

# Preflight check dei tool richiesti (stow) e avvisi per quelli opzionali
# (git, bat, mandb/makewhatis). Solo i tool indispensabili bloccano
# l'esecuzione.
check_tools() {
    local missing=()
    for cmd in stow; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "ERRORE: tool mancanti: ${missing[*]}" >&2
        echo "Installali con:" >&2
        if [[ "$(uname -s)" == "Darwin" ]]; then
            echo "  brew install ${missing[*]}" >&2
        else
            echo "  sudo apt install ${missing[*]}   # Debian/Ubuntu" >&2
            echo "  sudo dnf install ${missing[*]}   # Fedora" >&2
            echo "  sudo pacman -S ${missing[*]}     # Arch" >&2
        fi
        exit 1
    fi
    echo "Preflight check: OK (stow presente)"

    # --- Tool opzionali: avvisa, non bloccare. -------------------
    if ! command -v git >/dev/null 2>&1; then
        echo "Nota: 'git' non trovato. Non serve per lo stow," >&2
        echo "      ma serve per clonare/aggiornare il repo." >&2
    fi
    if [ -f "$REPO_ROOT/zsh/.zshrc" ] && ! command -v bat >/dev/null 2>&1; then
        echo "Nota: 'bat' non trovato. L'alias 'cat' in zsh/.zshrc" >&2
        echo "      verrà ignorato. Installalo con 'brew install bat'" >&2
        echo "      (macOS) oppure 'apt install bat' (Debian/Ubuntu)." >&2
    fi
    if ! command -v mandb >/dev/null 2>&1 \
       && ! command -v makewhatis >/dev/null 2>&1 \
       && [ ! -x /usr/libexec/makewhatis ] \
       && [ -d "$TARGET/.local/share/man" ]; then
        echo "Nota: né 'mandb' né 'makewhatis' trovati." >&2
        echo "      Il database delle man page non verrà aggiornato." >&2
        echo "      'man concat' funzionerà comunque; 'apropos' potrebbe non trovarlo." >&2
    fi
}

# Aggiorna il database delle man page utente sotto TARGET, se la directory
# esiste.
# - Linux: 'mandb' (man-db).
# - macOS: 'makewhatis' (spesso in /usr/libexec).
# - Se nessuno dei due è disponibile, avvisa ma non blocca.
update_man_db() {
    local man_dir="$TARGET/.local/share/man"
    [ -d "$man_dir" ] || return 0

    if command -v mandb >/dev/null 2>&1; then
        echo "Aggiornamento database man (mandb)..."
        mandb -q "$man_dir" 2>/dev/null || true
    elif command -v makewhatis >/dev/null 2>&1; then
        echo "Aggiornamento database man (makewhatis)..."
        makewhatis "$man_dir" 2>/dev/null || true
    elif [ -x /usr/libexec/makewhatis ]; then
        echo "Aggiornamento database man (/usr/libexec/makewhatis)..."
        /usr/libexec/makewhatis "$man_dir" 2>/dev/null || true
    else
        echo "Nota: nessun tool per aggiornare il database man (mandb/makewhatis)." >&2
        echo "      'man concat' funzionerà comunque." >&2
    fi
}

# ============================================================
# PARSING ARGOMENTI
# ============================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        -D|--delete)  MODE="unstow"; shift ;;
        -n|--dry-run) DRY_RUN=1;     shift ;;
        -t|--target)
            if [[ -z "${2:-}" ]]; then
                echo "Errore: -t/--target richiede un argomento." >&2
                usage >&2
                exit 1
            fi
            TARGET="$2"; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        --)           shift; EXPLICIT_PKGS+=("$@"); break ;;
        -*)           echo "Opzione sconosciuta: $1" >&2; usage >&2; exit 1 ;;
        *)            EXPLICIT_PKGS+=("$1"); shift ;;
    esac
done

# ============================================================
# VALIDAZIONE TARGET
# ============================================================

if [[ ! -d "$TARGET" ]]; then
    echo "Errore: target '$TARGET' non è una directory." >&2
    exit 1
fi

# ============================================================
# PREFLIGHT CHECK
# ============================================================

check_tools

cd "$REPO_ROOT"

# ============================================================
# COSTRUZIONE LISTA PACCHETTI
# ============================================================

PKGS=()
if [[ ${#EXPLICIT_PKGS[@]} -gt 0 ]]; then
    for p in "${EXPLICIT_PKGS[@]}"; do
        if [[ ! -d "$p" ]]; then
            echo "Errore: '$p' non è una directory in $REPO_ROOT" >&2
            exit 1
        fi
        PKGS+=("$p")
    done
else
    for d in */; do
        d="${d%/}"
        [[ -z "$d" ]] && continue
        [[ "$d" == .* ]] && continue
        is_excluded "$d" && continue
        PKGS+=("$d")
    done
fi

if [[ ${#PKGS[@]} -eq 0 ]]; then
    echo "Nessun pacchetto da processare." >&2
    exit 0
fi

# ============================================================
# ESECUZIONE STOW
# ============================================================

STOW_FLAGS=(--no-folding -t "$TARGET")
if [[ "$MODE" == "unstow" ]]; then
    STOW_FLAGS+=(-D)
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
    STOW_FLAGS+=(-n -v)
fi

echo "Repo:    $REPO_ROOT"
echo "Target:  $TARGET"
echo "Modo:    $MODE"
echo "Folding: disabilitato (--no-folding)"
[[ "$DRY_RUN" -eq 1 ]] && echo "Dry-run: sì (nessuna modifica)"
echo "Pacchetti: ${PKGS[*]}"
echo

errors=0
for pkg in "${PKGS[@]}"; do
    echo ">>> stow ${STOW_FLAGS[*]} $pkg"
    if ! stow "${STOW_FLAGS[@]}" "$pkg"; then
        echo "    [!] errore su pacchetto '$pkg'" >&2
        errors=$((errors + 1))
    fi
    echo
done

# ============================================================
# AGGIORNAMENTO DATABASE MAN
# ============================================================

if [[ "$DRY_RUN" -eq 0 ]] && [[ "$MODE" == "stow" ]]; then
    update_man_db
fi

# ============================================================
# RIEPILOGO FINALE
# ============================================================

if [[ "$errors" -gt 0 ]]; then
    echo "Completato con $errors errori su ${#PKGS[@]} pacchetti." >&2
    echo "Suggerimento: in caso di conflitti, sposta/backuppa il file esistente" >&2
    echo "nella home, oppure usa 'stow --adopt' con cautela." >&2
    exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Dry-run completato. Nessuna modifica effettuata."
else
    echo "Fatto: ${#PKGS[@]} pacchetti processati."
fi