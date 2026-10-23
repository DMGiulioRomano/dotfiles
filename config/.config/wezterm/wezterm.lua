local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Le tue impostazioni esistenti (font, colori, ecc.)
config.font = wezterm.font('JetBrains Mono')
config.font_size = 15.0

-- tasto option sinistro invia il carattere composto ~
config.send_composed_key_when_left_alt_is_pressed = true

-- disabilita 'dead key' per evitare che tilde richieda secondo tasto
config.use_dead_keys = false

-- Definizione delle scorciatoie personalizzate
config.keys = {
  -- Aumenta la dimensione del font con Cmd + Shift + = (cioè Cmd + +)
  {
    key = '+',
    mods = 'SUPER',
    action = wezterm.action.IncreaseFontSize,
  },
  -- Diminuisce la dimensione del font con Cmd + -
  {
    key = '-',
    mods = 'SUPER',
    action = wezterm.action.DecreaseFontSize,
  },
  -- Ripristina la dimensione del font con Cmd + 0
  {
    key = '0',
    mods = 'SUPER',
    action = wezterm.action.ResetFontSize,
  },
  -- Option + Freccia Sinistra → Alt+b (indietro di una parola)
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = wezterm.action.SendKey { mods = 'ALT', key = 'b' },
  },
  -- Option + Freccia Destra → Alt+f (avanti di una parola)
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = wezterm.action.SendKey { mods = 'ALT', key = 'f' },
  },
  -- Cmd + Freccia Sinistra → Ctrl+A (inizio riga)
  {
    key = 'LeftArrow',
    mods = 'SUPER',
    action = wezterm.action.SendKey { mods = 'CTRL', key = 'a' },
  },
  -- Cmd + Freccia Destra → Ctrl+E (fine riga)
  {
    key = 'RightArrow',
    mods = 'SUPER',
    action = wezterm.action.SendKey { mods = 'CTRL', key = 'e' },
  },
}

config.color_scheme = 'shades-of-purple'

-- Forza WezTerm a usare il titolo del pannello attivo,
-- aggirando il problema di Neovim con TERM=wezterm
wezterm.on('format-tab-title', function(tab)
  -- Usa il titolo del pannello attivo se disponibile
  local pane_title = tab.active_pane.title
  if pane_title and #pane_title > 0 then
    return pane_title
  end
  -- Altrimenti, usa il titolo predefinito della tab
  return tab.tab_title
end)

return config
