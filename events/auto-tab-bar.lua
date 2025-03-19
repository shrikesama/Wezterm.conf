local wezterm = require('wezterm')

-- TODO: 
M.setup = function(opts)
    wezterm.on("update-status", function(window, pane)
       local tab = window:active_tab()
       local active_process = pane:get_foreground_process_name() or ""
       
       local hide_tab_bar_for = { "nvim" }
       local should_hide = false

       -- 只有当当前 tab 中仅有一个 pane 时才进行判断
       if #tab.panes == 1 then
          for _, proc in ipairs(hide_tab_bar_for) do
             if active_process:find(proc) then
                should_hide = true
                break
             end
          end
       end

       window:set_config_overrides({
          enable_tab_bar = not should_hide,
       })
    end)
end

return M
