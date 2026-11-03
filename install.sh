#!/usr/bin/env bash
# install.sh — attiva (o disattiva) tutti i pacchetti Stow del repo.
#
# Uso:
#   ./install.sh                     # stow di tutti (con filtro shell auto)
#   ./install.sh --shell=zsh         # forza zsh
#   ./install.sh --shell=both        # zsh + bash
#   ./install.sh --shell=none        # solo pacchetti non-shell
#   ./install.sh -D                  # unstow di tutti (nessun filtro)
#   ./install.sh -n                  # dry-run
#   ./install.sh -t DIR              # target diverso da $HOME
#   ./install.sh -y                  # installa i tool mancanti senza chiedere
#   ./install.sh --no-install        # non offrire installazione automatica
#   ./install.sh nvim zsh            # stow solo dei pacchetti indicati
#   ./install.sh -h                  # aiuto
#
# Licenza: MIT
set -euo pipefail

shopt -s nullglob

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"
MODE="stow"          # stow | unstow
DRY_RUN=0
AUTO_INSTALL=0       # -y
NO_INSTALL=0         # --no-install
SHELL_MODE="auto"    # auto | zsh | bash | both | none
PM_CHOICE="auto"     # auto | brew | port (solo macOS)
MAC_PM=""            # gestore scelto su macOS, valorizzato da ensure_macos_pm
EXPLICIT_PKGS=()

HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
MACPORTS_INSTALL_URL="https://www.macports.org/install.php"

EXCLUDE_DIRS=(
    .git
    .github
    scripts
)

# ============================================================
# USAGE
# ============================================================

usage() {
    cat <<EOF
Uso: $(basename "$0") [opzioni] [pacchetto...]

Attiva (o disattiva) i pacchetti Stow presenti in: $REPO_ROOT
Target: $TARGET

Opzioni:
  -D, --delete            Disattiva i pacchetti (stow -D) invece di attivarli
  -n, --dry-run           Mostra i comandi senza eseguirli
  -t, --target DIR        Directory di destinazione (default: \$HOME)
  -y, --yes               Installa automaticamente i tool mancanti
      --no-install        Non offrire l'installazione automatica
      --pm=MODE           Gestore di pacchetti su macOS:
                            auto  (default) — brew se c'è, poi MacPorts se c'è,
                                              altrimenti prova a installare brew
                            brew  — solo Homebrew (lo installa se manca)
                            port  — solo MacPorts
      --shell=MODE        Quali pacchetti shell stoware:
                            auto  (default) — rileva da \$SHELL
                            zsh   — solo zsh/
                            bash  — solo bash/
                            both  — zsh/ e bash/
                            none  — nessuno (solo shell/ e altri)
                          In modalità -D il filtro non si applica:
                          vengono processati tutti i pacchetti.
  -h, --help              Mostra questo aiuto

Senza argomenti pacchetto, lo script usa tutte le directory di primo livello
del repo (escluse: ${EXCLUDE_DIRS[*]}) e, in modalità stow, filtra i
pacchetti shell secondo --shell.

Esempi:
  ./install.sh                    # stow di tutti (shell rilevata)
  ./install.sh --shell=both       # zsh + bash insieme
  ./install.sh -D                 # unstow di tutti
  ./install.sh nvim zsh           # stow solo di nvim e zsh
  ./install.sh -n                 # dry-run su tutti
  ./install.sh -y                 # stow + installa tool mancanti senza chiedere
  ./install.sh --no-install       # mostra i comandi di installazione ed esce
EOF
}

is_excluded() {
    local name="$1" ex
    for ex in "${EXCLUDE_DIRS[@]}"; do
        [[ "$name" == "$ex" ]] && return 0
    done
    return 1
}

# ============================================================
# RILEVAMENTO OS / DISTRO / PACKAGE MANAGER
# ============================================================

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Su un Mac appena configurato il PATH di questi gestori arriva da ~/.zprofile,
# che è proprio uno dei file che questo script deve ancora installare.
refresh_macos_path() {
    local d
    for d in /opt/local/sbin /opt/local/bin /usr/local/bin /opt/homebrew/bin; do
        [ -d "$d" ] || continue
        case ":$PATH:" in
            *":$d:"*) ;;
            *) PATH="$d:$PATH" ;;
        esac
    done
    export PATH
}

# Chiede conferma; restituisce 0 solo se si può procedere con l'azione.
confirm_action() {
    [ "$DRY_RUN" -eq 1 ] && return 1
    if [ "$NO_INSTALL" -eq 1 ]; then
        echo "(--no-install) Nessuna installazione eseguita." >&2
        return 1
    fi
    [ "$AUTO_INSTALL" -eq 1 ] && return 0
    if [ ! -t 0 ]; then
        echo "stdin non è un terminale: nessuna installazione automatica." >&2
        echo "Rilancia con -y per procedere." >&2
        return 1
    fi
    local answer=""
    read -r -p "$1 [y/N] " answer || true
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
    esac
    return 1
}

install_homebrew() {
    echo
    echo "Homebrew non trovato."
    echo "Comando: /bin/bash -c \"\$(curl -fsSL $HOMEBREW_INSTALL_URL)\""
    echo
    confirm_action "Provo a installare Homebrew ora?" || return 1

    local script
    if ! script=$(curl -fsSL "$HOMEBREW_INSTALL_URL"); then
        echo "Download dell'installer di Homebrew fallito." >&2
        return 1
    fi
    if [ "$AUTO_INSTALL" -eq 1 ]; then
        NONINTERACTIVE=1 /bin/bash -c "$script" || return 1
    else
        /bin/bash -c "$script" || return 1
    fi
    refresh_macos_path
    command -v brew >/dev/null 2>&1
}

# Sceglie il gestore senza installare nulla: se c'è già, si usa quello.
detect_macos_pm() {
    MAC_PM=""
    refresh_macos_path
    case "$PM_CHOICE" in
        brew) command -v brew >/dev/null 2>&1 && MAC_PM=brew ;;
        port) command -v port >/dev/null 2>&1 && MAC_PM=port ;;
        auto)
            if command -v brew >/dev/null 2>&1; then
                MAC_PM=brew
            elif command -v port >/dev/null 2>&1; then
                MAC_PM=port
            fi
            ;;
    esac
    [ -n "$MAC_PM" ]
}

# Come detect_macos_pm, ma se non c'è alcun gestore prova a installare Homebrew.
# MacPorts non si installa da qui: il pacchetto dipende dalla versione di macOS.
ensure_macos_pm() {
    detect_macos_pm && return 0

    if [ "$PM_CHOICE" != "port" ] && install_homebrew; then
        MAC_PM=brew
        return 0
    fi
    [ "$PM_CHOICE" = "brew" ] && return 1

    echo "Homebrew non disponibile: si ripiega su MacPorts, che va installato a mano." >&2
    echo "  1. xcode-select --install" >&2
    echo "  2. Scarica il pacchetto per la tua versione di macOS: $MACPORTS_INSTALL_URL" >&2
    echo "  3. Rilancia questo script." >&2
    return 1
}

detect_pkg_manager() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case " ${ID:-} ${ID_LIKE:-} " in
            *" debian "*|*" ubuntu "*|*" linuxmint "*|*" pop "*)
                command -v apt-get >/dev/null 2>&1 && { echo apt; return 0; } ;;
            *" fedora "*|*" rhel "*|*" centos "*|*" rocky "*|*" alma "*)
                command -v dnf >/dev/null 2>&1 && { echo dnf; return 0; } ;;
            *" arch "*|*" manjaro "*|*" endeavouros "*)
                command -v pacman >/dev/null 2>&1 && { echo pacman; return 0; } ;;
            *" opensuse "*|*" suse "*)
                command -v zypper >/dev/null 2>&1 && { echo zypper; return 0; } ;;
            *" alpine "*)
                command -v apk >/dev/null 2>&1 && { echo apk; return 0; } ;;
            *" void "*)
                command -v xbps-install >/dev/null 2>&1 && { echo xbps; return 0; } ;;
            *" gentoo "*)
                command -v emerge >/dev/null 2>&1 && { echo emerge; return 0; } ;;
        esac
    fi

    local pm
    for pm in brew apt-get dnf pacman zypper apk xbps-install emerge; do
        if command -v "$pm" >/dev/null 2>&1; then
            case "$pm" in
                apt-get)      echo apt ;;
                xbps-install) echo xbps ;;
                *)            echo "$pm" ;;
            esac
            return 0
        fi
    done
    return 1
}

pkg_name_for() {
    local tool="$1" pm="$2"
    case "$tool" in
        stow) echo stow ;;
        git)  echo git ;;
        bat)  echo bat ;;
        wl-copy|wl-clipboard)
            echo wl-clipboard ;;
        xclip) echo xclip ;;
        xsel)  echo xsel ;;
	mandb|makewhatis)
            case "$pm" in
                apk) echo mandoc ;;
                *)   echo man-db ;;
            esac ;;
        *) echo "$tool" ;;
    esac
}

build_install_cmd() {
    local pm="$1"; shift
    local pkgs=("$@")
    [ ${#pkgs[@]} -eq 0 ] && return 1

    local SUDO=""
    if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
        SUDO="sudo "
    fi

    case "$pm" in
        brew)   echo "brew install ${pkgs[*]}" ;;
        port)   echo "${SUDO}$(command -v port) -N install ${pkgs[*]}" ;;
        apt)    echo "${SUDO}apt-get update && ${SUDO}apt-get install -y ${pkgs[*]}" ;;
        dnf)    echo "${SUDO}dnf install -y ${pkgs[*]}" ;;
        pacman) echo "${SUDO}pacman -S --noconfirm --needed ${pkgs[*]}" ;;
        zypper) echo "${SUDO}zypper --non-interactive install ${pkgs[*]}" ;;
        apk)    echo "${SUDO}apk add ${pkgs[*]}" ;;
        xbps)   echo "${SUDO}xbps-install -y ${pkgs[*]}" ;;
        emerge) echo "${SUDO}emerge --ask=n ${pkgs[*]}" ;;
        *)      return 1 ;;
    esac
}

prompt_and_install() {
    local kind="$1"; shift
    local tools=("$@")
    [ ${#tools[@]} -eq 0 ] && return 0

    local pm
    if is_macos; then
        ensure_macos_pm || return 1
        pm="$MAC_PM"
    elif ! pm=$(detect_pkg_manager); then
        echo "Nessun gestore di pacchetti riconosciuto per installare: ${tools[*]}" >&2
        return 1
    fi

    local pkgs=() t
    for t in "${tools[@]}"; do
        pkgs+=("$(pkg_name_for "$t" "$pm")")
    done

    local cmd
    if ! cmd=$(build_install_cmd "$pm" "${pkgs[@]}"); then
        echo "Impossibile costruire un comando per '$pm'." >&2
        return 1
    fi

    echo
    echo "Tool $kind mancanti: ${tools[*]}"
    echo "Package manager rilevato: $pm"
    echo "Comando: $cmd"
    echo

    if ! confirm_action "Vuoi eseguirlo ora?"; then
        echo "Salto. Esegui manualmente:" >&2
        echo "  $cmd" >&2
        return 1
    fi

    echo ">>> $cmd"
    if ! bash -c "$cmd"; then
        echo "Installazione fallita." >&2
        return 1
    fi
    return 0
}

# ============================================================
# PREFLIGHT CHECK
# ============================================================

check_tools() {
    local missing_req=()
    local missing_opt=()

    command -v stow >/dev/null 2>&1 || missing_req+=(stow)

    if ! command -v git >/dev/null 2>&1; then missing_opt+=(git); fi

    # 'bat' serve solo se stiamo per stoware zsh/ (dove .zshrc fa alias cat='bat ...').
    # Calcoliamo se zsh sarà effettivamente selezionato, senza fidarci di $SHELL_MODE
    # (in 'auto' va risolta la shell concreta).
    local will_use_zsh=0
    case "$SHELL_MODE" in
        zsh|both) will_use_zsh=1 ;;
        bash|none) will_use_zsh=0 ;;
        auto)
            [ "$(detect_shell_family)" = "zsh" ] && will_use_zsh=1
            ;;
    esac
    if [ "$will_use_zsh" -eq 1 ] \
       && [ -f "$REPO_ROOT/zsh/.zshrc" ] \
       && ! command -v bat >/dev/null 2>&1; then
        missing_opt+=(bat)
    fi

    if [[ "$(uname -s)" != "Darwin" ]] && [[ "$MODE" = "stow" ]]; then
        local has_clip=0
        command -v wl-copy >/dev/null 2>&1 && has_clip=1
        command -v xclip   >/dev/null 2>&1 && has_clip=1
        command -v xsel    >/dev/null 2>&1 && has_clip=1

        local will_use_shell=0
        if [[ ${#EXPLICIT_PKGS[@]} -eq 0 ]]; then
            will_use_shell=1
        else
            local p
            for p in "${EXPLICIT_PKGS[@]}"; do
                [[ "$p" == "shell" ]] && will_use_shell=1
            done
        fi

        if [ "$has_clip" -eq 0 ] && [ "$will_use_shell" -eq 1 ] \
           && [ -f "$REPO_ROOT/shell/.aliases" ]; then
            if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
                missing_opt+=(wl-copy)
            elif [[ -n "${DISPLAY:-}" ]]; then
                missing_opt+=(xclip)
            fi
            # Se nessuna delle due variabili è impostata (es. server
            # headless), non suggeriamo nulla: non c'è clipboard.
        fi
    fi


    local has_man_tool=0
    if command -v mandb >/dev/null 2>&1; then has_man_tool=1; fi
    if command -v makewhatis >/dev/null 2>&1; then has_man_tool=1; fi
    if [ -x /usr/libexec/makewhatis ]; then has_man_tool=1; fi

    # 'mandb' serve solo in modalità stow (in unstow non aggiorniamo il db).
    # Guardiamo il repo (non il target) così l'avviso scatta anche al primo run.
    if [ "$has_man_tool" -eq 0 ] \
       && [ "$MODE" = "stow" ] \
       && [ -d "$REPO_ROOT/local-bin/.local/share/man" ]; then
        missing_opt+=(mandb)
    fi

    if [ ${#missing_req[@]} -gt 0 ]; then
        echo "ERRORE: tool obbligatori mancanti: ${missing_req[*]}" >&2
        if ! prompt_and_install "obbligatorio" "${missing_req[@]}"; then
            echo "Impossibile continuare senza: ${missing_req[*]}" >&2
            exit 1
        fi
        local t
        for t in "${missing_req[@]}"; do
            if ! command -v "$t" >/dev/null 2>&1; then
                echo "ERRORE: '$t' ancora mancante dopo l'installazione." >&2
                echo "Potrebbe servire riaprire la shell o aggiornare PATH." >&2
                exit 1
            fi
        done
    fi
    echo "Preflight check: OK (stow presente)"

    if [ ${#missing_opt[@]} -gt 0 ]; then
        if ! prompt_and_install "opzionale" "${missing_opt[@]}"; then
            local t
            for t in "${missing_opt[@]}"; do
                echo "Nota: '$t' non trovato (opzionale, si prosegue)." >&2
            done
        fi
    fi
}

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
# GESTIONE SHELL (zsh / bash)
# ============================================================

detect_shell_family() {
    local base
    base=$(basename "${SHELL:-}")
    case "$base" in
        zsh)  echo zsh ;;
        bash) echo bash ;;
        *)    echo "" ;;
    esac
}

# Traduce SHELL_MODE nel set di pacchetti shell da tenere: zsh|bash|both|none.
# In modalità auto rileva da $SHELL e verifica che il pacchetto esista.
resolve_shell_keep() {
    case "$SHELL_MODE" in
        zsh)  echo zsh ;;
        bash) echo bash ;;
        both) echo both ;;
        none) echo none ;;
        auto)
            local detected
            detected=$(detect_shell_family)
            if [[ -z "$detected" ]]; then
                echo "Shell corrente non riconosciuta ('${SHELL:-?}'): salto zsh/bash." >&2
                echo none
                return 0
            fi
            if [[ ! -d "$REPO_ROOT/$detected" ]]; then
                echo "Shell rilevata: $detected; pacchetto '$detected/' non presente: salto." >&2
                echo none
                return 0
            fi
            echo "Shell rilevata: $detected" >&2
            echo "$detected"
            ;;
    esac
}

# Filtra PKGS tenendo solo i pacchetti shell indicati in KEEP.
# I pacchetti non-shell sono sempre mantenuti.
apply_shell_filter() {
    local keep="$1" filtered=() p
    [ "$keep" = "both" ] && keep="zsh,bash"
    for p in "${PKGS[@]}"; do
        case "$p" in
            zsh|bash)
                case ",$keep," in
                    *",$p,"*) filtered+=("$p") ;;
                esac
                ;;
            *) filtered+=("$p") ;;
        esac
    done
    PKGS=("${filtered[@]}")
}

# ============================================================
# PARSING ARGOMENTI
# ============================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        -D|--delete)  MODE="unstow"; shift ;;
        -n|--dry-run) DRY_RUN=1;     shift ;;
        -y|--yes)     AUTO_INSTALL=1; shift ;;
        --no-install) NO_INSTALL=1;   shift ;;
        --pm=*)       PM_CHOICE="${1#--pm=}"; shift ;;
        --shell=*)    SHELL_MODE="${1#--shell=}"; shift ;;
        --shell)
            if [[ -z "${2:-}" ]]; then
                echo "Errore: --shell richiede un argomento (auto|zsh|bash|both|none)." >&2
                exit 1
            fi
            SHELL_MODE="$2"; shift 2 ;;
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

if [ "$AUTO_INSTALL" -eq 1 ] && [ "$NO_INSTALL" -eq 1 ]; then
    echo "Errore: -y e --no-install sono incompatibili." >&2
    exit 1
fi

case "$PM_CHOICE" in
    auto|brew|port) ;;
    *)
        echo "Valore --pm non valido: $PM_CHOICE" >&2
        echo "Valori ammessi: auto, brew, port" >&2
        exit 1
        ;;
esac

# Valida --shell fail-fast (prima di toccare il filesystem).
case "$SHELL_MODE" in
    auto|none|both) ;;
    zsh)
        if [[ ! -d "$REPO_ROOT/zsh" ]]; then
            echo "Errore: --shell=zsh ma il pacchetto 'zsh/' non esiste." >&2
            exit 1
        fi
        ;;
    bash)
        if [[ ! -d "$REPO_ROOT/bash" ]]; then
            echo "Errore: --shell=bash ma il pacchetto 'bash/' non esiste." >&2
            exit 1
        fi
        ;;
    *)
        echo "Valore --shell non valido: $SHELL_MODE" >&2
        echo "Valori ammessi: auto, zsh, bash, both, none" >&2
        exit 1
        ;;
esac

# ============================================================
# VALIDAZIONE TARGET
# ============================================================

if [[ ! -d "$TARGET" ]]; then
    echo "Errore: target '$TARGET' non è una directory." >&2
    exit 1
fi

# Normalizza TARGET in assoluto PRIMA di spostarci in REPO_ROOT.
# Altrimenti un target relativo (es. -t ./test) verrebbe risolto
# rispetto a REPO_ROOT all'interno di stow.
if ! TARGET="$(cd "$TARGET" && pwd)"; then
    echo "Errore: impossibile risolvere il path assoluto del target." >&2
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

    # Filtro shell solo in modalità stow (in unstow vogliamo disfare tutto).
    if [[ "$MODE" == "stow" ]]; then
        keep=$(resolve_shell_keep)
        apply_shell_filter "$keep"
    fi
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
