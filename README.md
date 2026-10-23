# Dotfiles

Dotfiles personali, gestiti con [GNU Stow](https://www.gnu.org/software/stow/).

## Requisiti

- **`stow`** — obbligatorio (usato da `install.sh`)
- **`git`** — consigliato (per clonare/aggiornare il repo)
- **`bat`** — opzionale (per l'alias `cat` in `zsh/.zshrc`)
- **`mandb`** o **`makewhatis`** — opzionale (per indicizzare le man page utente)
- **`wl-clipboard`** (Wayland) oppure **`xclip`/`xsel`** (X11) — opzionale
  (per la copia in clipboard della funzione `concat`, solo su Linux)

Se `stow` manca, `install.sh` si ferma e suggerisce il comando di installazione
per il tuo sistema operativo. Gli altri tool mancanti producono solo un avviso.

## Installazione

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh              # stow di tutti i pacchetti
```
Opzioni utili:


```sh
./install.sh -n           # dry-run (non modifica nulla)
./install.sh -D           # unstow di tutti i pacchetti
./install.sh -t /tmp/t    # target diverso da $HOME
./install.sh nvim zsh     # stow solo dei pacchetti indicati
./install.sh -y           # stow + installa i tool mancanti senza chiedere
./install.sh --no-install # mostra i comandi di installazione ed esce
./install.sh -h           # aiuto
```

## Struttura

| Pacchetto   | Cosa contiene |
|-------------|---------------|
| `shell`     | `~/.aliases` — alias condivisi fra zsh e bash |
| `zsh`       | `~/.zshrc`, `~/.zprofile` (sourcano `~/.aliases`) |
| `bash`      | `~/.bashrc`, `~/.bash_profile` (opzionale, sourcano `~/.aliases`) |
| `local-bin` | `~/.local/bin/concat` + man page |
| `nvim`      | `~/.config/nvim/init.lua` |
| `wezterm`   | `~/.wezterm.lua` |

## Selezione shell

Di default `install.sh` rileva la shell da `$SHELL` e stowa solo il
pacchetto corrispondente (`zsh` o `bash`), oltre a `shell` e agli altri.
Override:

```sh
./install.sh --shell=both   # zsh + bash
./install.sh --shell=none   # solo shell/ + altri
./install.sh zsh            # lista esplicita: bypassa il filtro
./install.sh -D             # unstow: nessun filtro, disfa tutto
```

Con `--shell=auto` (default), se `$SHELL` non è né zsh né bash viene
stampato un avviso e i pacchetti shell vengono saltati; `shell/`
(alias condivisi) viene comunque stowato.

## Licenza

MIT — vedi [`LICENSE`](LICENSE).
