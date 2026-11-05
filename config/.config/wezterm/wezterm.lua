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
  -- Option + 9 → backtick (`), assente nel layout Italian - Pro
  {
    key = '9',
    mods = 'OPT',
    action = wezterm.action.SendString '`',
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
  -- Cmd + Freccia Su → Pagina su (scorre la chat di Claude Code)
  {
    key = 'UpArrow',
    mods = 'SUPER',
    action = wezterm.action.SendKey { key = 'PageUp' },
  },
  -- Cmd + Freccia Giù → Pagina giù
  {
    key = 'DownArrow',
    mods = 'SUPER',
    action = wezterm.action.SendKey { key = 'PageDown' },
  },
}

config.color_scheme = 'shades-of-purple'

-- Tab nella barra del titolo, alla stessa altezza dei pulsanti della finestra
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'

-- Barra del titolo e tab dello stesso viola del tema
local tema = wezterm.color.get_builtin_schemes()[config.color_scheme]
config.window_frame = {
  active_titlebar_bg = tema.background,
  inactive_titlebar_bg = tema.background,
}
config.colors = {
  tab_bar = {
    inactive_tab_edge = tema.background,
    active_tab = { bg_color = tema.ansi[5], fg_color = tema.foreground },
    inactive_tab = { bg_color = tema.background, fg_color = tema.foreground },
    inactive_tab_hover = { bg_color = tema.ansi[5], fg_color = tema.foreground },
    new_tab = { bg_color = tema.background, fg_color = tema.foreground },
    new_tab_hover = { bg_color = tema.ansi[5], fg_color = tema.foreground },
  },
}

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
