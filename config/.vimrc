" ~/.vimrc — impostazioni comuni a Vim e Neovim

" Usa il registro di sistema per yank/put di default.
" Richiede +clipboard in Vim; in Neovim richiede un provider.
if has('clipboard')
    set clipboard=unnamedplus
endif
" ==== Numeri di riga ====
set number              " numero assoluto sulla riga del cursore
set relativenumber      " numeri relativi sulle altre (ottimo per 10j, 5k...)
set cursorline          " evidenzia la riga corrente

" ==== Indentazione ====
set tabstop=4           " una tab = 4 spazi visivi
set shiftwidth=4        " indentazione con >> e << = 4 spazi
set softtabstop=4       " Tab in insert mode = 4 spazi
set expandtab           " Tab → spazi (metti noexpandtab se preferisci tab veri)
set autoindent          " mantieni l'indentazione della riga precedente
set smartindent         " indentazione intelligente per blocchi { }
set shiftround          " >> e << arrotondano a multipli di shiftwidth

" ==== Ricerca ====
set incsearch           " ricerca incrementale mentre digiti
set hlsearch            " evidenzia tutte le occorrenze
set ignorecase          " ricerca case-insensitive...
set smartcase           " ...tranne se scrivi maiuscole
" (per cancellare l'evidenziazione: :noh  oppure mappa sotto)

" ==== Interfaccia ====
set showcmd             " mostra i comandi parziali in basso a destra
set showmatch           " evidenzia la parentesi corrispondente
set ruler               " mostra riga:colonna in basso a destra
set wildmenu            " autocompletamento comandi con Tab
set wildmode=longest:full,full
set laststatus=2        " statusline sempre visibile
set scrolloff=8         " tieni 8 righe di contesto sopra/sotto il cursore
set sidescrolloff=8     " idem in orizzontale
set colorcolumn=80      " riga guida a colonna 80 (stile di codice)
set termguicolors       " colori 24-bit (se il terminale li supporta)

" ==== Comportamento ====
set hidden              " puoi cambiare buffer senza salvare
set mouse=a             " mouse attivo (utile per selezione/scroll)
set backspace=indent,eol,start   " backspace "umano" in insert mode
set splitright          " :vsplit apre a destra
set splitbelow          " :split apre sotto
set undofile            " undo persistente tra sessioni (vedi sotto)
set undodir=~/.vim/undo " dove salvare la history di undo

" ==== Performance / niceties ====
set updatetime=300      " aggiorna più spesso (utile per plugin/status)
set timeoutlen=500      " timeout per le mappature
set ttimeoutlen=10      " timeout per i codici terminale (Esc più reattivo)
set encoding=utf-8
set fileencoding=utf-8

" ==== Syntax & filetype ====
syntax on
filetype plugin indent on
