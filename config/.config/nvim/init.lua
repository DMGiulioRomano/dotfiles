-- Abilita l'impostazione del titolo della finestra
vim.opt.title = true

-- Imposta il titolo usando il nome del file corrente (%t) e uno stato modificato (%m)
-- Puoi personalizzare il formato come preferisci
vim.opt.titlestring = "%t%( %m%)"

-- Carica le impostazioni comuni definite in ~/.vimrc
local vimrc = vim.fn.expand('~/.vimrc')
if vim.fn.filereadable(vimrc) == 1 then
    vim.cmd('source ' .. vimrc)
end
