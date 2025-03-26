local wezterm = require('wezterm')
local platform = require('utils.platform')
local backdrops = require('utils.backdrops')
local act = wezterm.action

local mod = {}

if platform.is_mac then
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   mod.SUPER_REV = 'ALT|CTRL'
end

-- stylua: ignore
local keys = {
   -- misc/useful --
   {
      key = 'F1',
      mods = 'NONE',
      action = wezterm.action.Multiple {
         wezterm.action.ActivateCommandPalette,
         wezterm.action.ActivateKeyTable({ name = 'commandPalette' }),
      },
   },
   { key = 'F2',  mods = 'NONE',        action = 'ActivateCopyMode' },
   { key = 'F3',  mods = 'NONE',        action = act.ShowLauncher },
   { key = 'F4',  mods = 'NONE',        action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   { key = 'F5',  mods = 'NONE',        action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }), },
   { key = 'F11', mods = 'NONE',        action = act.ToggleFullScreen },
   { key = 'f',   mods = mod.SUPER_REV, action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE',        action = act.ShowDebugOverlay },
   { key = 'f',   mods = mod.SUPER,     action = act.Search({ CaseInSensitiveString = '' }) },
   {
      key = 'u',
      mods = mod.SUPER_REV,
      action = wezterm.action.QuickSelectArgs({
         label = 'open url',
         patterns = {
            '\\((https?://\\S+)\\)',
            '\\[(https?://\\S+)\\]',
            '\\{(https?://\\S+)\\}',
            '<(https?://\\S+)>',
            '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
         },
         action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info('opening: ' .. url)
            wezterm.open_with(url)
         end),
      }),
   },

   -- cursor movement --
   { key = 'LeftArrow',  mods = mod.SUPER, action = act.SendString '\u{1b}OH' },
   { key = 'RightArrow', mods = mod.SUPER, action = act.SendString '\u{1b}OF' },
   { key = 'Backspace',  mods = mod.SUPER, action = act.SendString '\u{15}' },

   -- copy/paste --
   { key = 'c',          mods = mod.SUPER, action = act.CopyTo('Clipboard') },
   { key = 'v',          mods = mod.SUPER, action = act.PasteFrom('Clipboard') },

   -- background controls --
   {
      key = [[/]],
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:random(window)
      end),
   },
   -- TODO: super + , => swtich tab
   -- {
   --    key = [[,]],
   --    mods = mod.SUPER,
   --    action = wezterm.action_callback(function(window, _pane)
   --       backdrops:cycle_back(window)
   --    end),
   -- },
   -- TODO: super + , => swtich tab
   -- {
   --    key = [[.]],
   --    mods = mod.SUPER,
   --    action = wezterm.action_callback(function(window, _pane)
   --       backdrops:cycle_forward(window)
   --    end),
   -- },
   {
      key = [[/]],
      mods = mod.SUPER_REV,
      action = act.InputSelector({
         title = 'InputSelector: Select Background',
         choices = backdrops:choices(),
         fuzzy = true,
         fuzzy_description = 'Select Background: ',
         action = wezterm.action_callback(function(window, _pane, idx)
            if not idx then
               return
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            backdrops:set_img(window, tonumber(idx))
         end),
      }),
   },
   {
      key = 'b',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:toggle_backdrop_mode(window)
      end)
   },

   -- window --
   -- window: spawn windows
   { key = 'n',  mods = mod.SUPER,     action = act.SpawnWindow },

   -- window: zoom window
   {
      key = '-',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width - 50
         local new_height = dimensions.pixel_height - 50
         window:set_inner_size(new_width, new_height)
      end)
   },
   {
      key = '=',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width + 50
         local new_height = dimensions.pixel_height + 50
         window:set_inner_size(new_width, new_height)
      end)
   },

   -- tabs --
   -- tabs: spawn+close
   {
      key = 't',
      mods = "LEADER",
      action = wezterm.action.ActivateKeyTable {
         name = "tab",
         timeout_milliseconds = 5000,
      },
   },
   { key = 't',  mods = mod.SUPER,     action = act.SpawnTab('DefaultDomain') },
   -- { key = 't',          mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = 'WSL:Ubuntu' }) },
   { key = 'w',  mods = mod.SUPER,     action = act.CloseCurrentTab({ confirm = false }) },

   -- tabs: navigation
   { key = ',',  mods = mod.SUPER,     action = act.ActivateTabRelative(-1) },
   { key = '.',  mods = mod.SUPER,     action = act.ActivateTabRelative(1) },
   { key = ',',  mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = '.',  mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

   -- tab: title
   { key = '0',  mods = mod.SUPER,     action = act.EmitEvent('tabs.manual-update-tab-title') },
   { key = '0',  mods = mod.SUPER_REV, action = act.EmitEvent('tabs.reset-tab-title') },

   -- tab: hide tab-bar
   { key = '9',  mods = mod.SUPER,     action = act.EmitEvent('tabs.toggle-tab-bar'), },
   { key = 'F9', mods = 'NONE',        action = wezterm.action.ShowTabNavigator },

   -- panes --
   -- panes key table: <leader + p>
   {
      key = 'p',
      mods = "LEADER",
      action = wezterm.action.ActivateKeyTable {
         name = "pane",
         timeout_milliseconds = 5000,
      },
   },

   -- panes: zoom+close pane
   { key = 'Enter', mods = mod.SUPER, action = act.TogglePaneZoomState },
   { key = 'w',     mods = mod.SUPER, action = act.CloseCurrentPane({ confirm = false }) },

   -- panes: navigation
   { key = 'k',     mods = mod.SUPER, action = act.ActivatePaneDirection('Up') },
   { key = 'j',     mods = mod.SUPER, action = act.ActivatePaneDirection('Down') },
   { key = 'h',     mods = mod.SUPER, action = act.ActivatePaneDirection('Left') },
   { key = 'l',     mods = mod.SUPER, action = act.ActivatePaneDirection('Right') },
   {
      key = 'p',
      mods = mod.SUPER_REV,
      action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
   },

   -- panes: scroll pane
   { key = 'u',        mods = mod.SUPER, action = act.ScrollByLine(-5) },
   { key = 'd',        mods = mod.SUPER, action = act.ScrollByLine(5) },
   { key = 'PageUp',   mods = 'NONE',    action = act.ScrollByPage(-0.75) },
   { key = 'PageDown', mods = 'NONE',    action = act.ScrollByPage(0.75) },

   -- key-tables --
   -- resizes fonts
   {
      key = 'f',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_font',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   }
}

-- stylua: ignore
local key_tables = {
   resize_font = {
      { key = 'k',      action = act.IncreaseFontSize },
      { key = 'j',      action = act.DecreaseFontSize },
      { key = 'r',      action = act.ResetFontSize },

      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },

   tab = {
      { key = 'e',      action = wezterm.action.ShowTabNavigator },

      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },

   pane = {
      -- adjustPaneSize
      { key = 'k', mod = mod.SUPER,                            action = act.AdjustPaneSize({ 'Up', 1 }) },
      { key = 'j', mod = mod.SUPER,                            action = act.AdjustPaneSize({ 'Down', 1 }) },
      { key = 'h', mod = mod.SUPER,                            action = act.AdjustPaneSize({ 'Left', 1 }) },
      { key = 'l', mod = mod.SUPER,                            action = act.AdjustPaneSize({ 'Right', 1 }) },
      -- panes: navigation
      -- panes: navigation
      { key = 'k', action = act.ActivatePaneDirection('Up') },
      { key = 'j', action = act.ActivatePaneDirection('Down') },
      { key = 'h', action = act.ActivatePaneDirection('Left') },
      { key = 'l', action = act.ActivatePaneDirection('Right') },
      {
         key = 'p',
         action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
      },
      -- spawn pane
      { key = 's',      action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
      { key = 'v',      action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },

      -- popKeytable
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
   commandPalette = {
      { key = 'h',      mods = mod.SUPER,      action = wezterm.action.SendKey { key = 'LeftArrow' } },
      { key = 'l',      mods = mod.SUPER,      action = wezterm.action.SendKey { key = 'RightArrow' } },
      { key = 'k',      mods = mod.SUPER,      action = wezterm.action.SendKey { key = 'UpArrow' } },
      { key = 'j',      mods = mod.SUPER,      action = wezterm.action.SendKey { key = 'DownArrow' } },

      -- popKeytable
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
}

local mouse_bindings = {
   -- Ctrl-click will open the link under the mouse cursor
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
}

return {
   native_macos_fullscreen_mode = true,
   disable_default_key_bindings = true,
   -- disable_default_mouse_bindings = true,
   leader = { key = '\\', mods = mod.SUPER, timeout_milliseconds = 2000 },
   keys = keys,
   key_tables = key_tables,
   mouse_bindings = mouse_bindings,
}
