# Dotfiles

Dotfiles personali, gestiti con [GNU Stow](https://www.gnu.org/software/stow/).

## Requisiti

- **`stow`** — obbligatorio (usato da `install.sh`)
- **`git`** — consigliato (per clonare/aggiornare il repo)
- **`bat`** — opzionale (per l'alias `cat` in `zsh/.zshrc`)
- **`mandb`** o **`makewhatis`** — opzionale (per indicizzare le man page utente)
- **`wl-clipboard`** (Wayland) oppure **`xclip`/`xsel`** (X11) — opzionale
  (per la copia in clipboard della funzione `concat`, solo su Linux)

Se `stow` manca, `install.sh` propone il comando di installazione per il tuo
sistema operativo e senza `stow` si ferma. Gli altri tool mancanti producono
solo un avviso.

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
./install.sh config zsh   # stow solo dei pacchetti indicati
./install.sh -y           # stow + installa i tool mancanti senza chiedere
./install.sh --no-install # mostra i comandi di installazione ed esce
./install.sh -h           # aiuto
```

## Programmi (solo macOS)

`tools.txt` elenca ciò che serve oltre a macOS. Di default `install.sh` installa
solo le cartelle; i programmi si chiedono esplicitamente:

```sh
./install.sh --audit       # sola lettura: cosa manca e cosa non è dichiarato
./install.sh --tools -n    # mostra cosa installerebbe, senza farlo
./install.sh --tools       # cartelle + programmi
./install.sh --tools-only  # solo programmi
```

Il gestore di pacchetti si sceglie così:

1. se c'è `brew`, usa `brew`;
2. altrimenti, se c'è MacPorts, usa MacPorts;
3. altrimenti prova a installare `brew`;
4. se non ci riesce, indica i passi per installare MacPorts a mano e si ferma:
   `xcode-select --install`, poi il
   [pacchetto per la tua versione di macOS](https://www.macports.org/install.php).

`--pm=brew` e `--pm=port` forzano la scelta, senza ripiegare sull'altro gestore.
MacPorts chiede la password di `sudo`.

`tools.txt` contiene quattro tipi di riga:

| Tipo     | Cosa fa |
|----------|---------|
| `pkg`    | comando da shell, con il nome del pacchetto per `brew` e per MacPorts |
| `script` | programma che si installa con il suo script ufficiale |
| `app`    | app grafica: non viene installata, compare in fondo con il link per scaricarla |
| `ignore` | glob che `--audit` non deve segnalare |

`--audit` confronta `tools.txt` con ciò che trova fuori dalle cartelle di sistema:
pacchetti richiesti al gestore, binari in `/usr/local/bin` e `~/.local/bin`,
pacchetti `.pkg` non Apple e app in `/Applications`. Quando installi qualcosa di
nuovo, ti dice che va aggiunto alla lista.

## Struttura

| Pacchetto   | Cosa contiene |
|-------------|---------------|
| `shell`     | `~/.aliases` — alias condivisi fra zsh e bash |
| `zsh`       | `~/.zshrc`, `~/.zprofile` (sourcano `~/.aliases`) |
| `bash`      | `~/.bashrc`, `~/.bash_profile` (opzionale, sourcano `~/.aliases`) |
| `local-bin` | `~/.local/bin/concat` + man page |
| `config`    | `~/.config/nvim/init.lua`, `~/.config/wezterm/wezterm.lua`, `~/.vimrc` |

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
