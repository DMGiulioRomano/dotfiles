# _settings_job_desktop

Dotfiles personali, gestiti con [GNU Stow](https://www.gnu.org/software/stow/).

## Requisiti

- **`stow`** — obbligatorio (usato da `install.sh`)
- **`git`** — consigliato (per clonare/aggiornare il repo)
- **`bat`** — opzionale (per l'alias `cat` in `zsh/.zshrc`)
- **`mandb`** o **`makewhatis`** — opzionale (per indicizzare le man page utente)

Se `stow` manca, `install.sh` si ferma e suggerisce il comando di installazione
per il tuo sistema operativo. Gli altri tool mancanti producono solo un avviso.

## Installazione

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh              # stow di tutti i pacchetti