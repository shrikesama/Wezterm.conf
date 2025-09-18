local wezterm = require('wezterm')
local Cells = require('utils.cells')

local nf = wezterm.nerdfonts
local attr = Cells.attr

local M = {}

-- Icons (no ASCII fallbacks per requirement)
local GLYPH_WORKSPACE = nf.md_briefcase or ''
local GLYPH_WINDOW = nf.fa_window_maximize or ''

-- Colors
---@type table<string, Cells.SegmentColors>
local colors = {
    ws_block     = { bg = '#fab387', fg = '#1c1b19' },
    win_active   = { bg = '#A4CF4A', fg = '#11111B' },
    win_inactive = { bg = '#45475A', fg = '#1C1B19' },
}

-- UTF-8 safe ellipsis
local function ellipsize_utf8(s, max_chars)
    if not s or max_chars <= 0 then return '' end
    local len = utf8.len(s)
    if not len or len <= max_chars then return s end
    if max_chars <= 3 then
        local p = utf8.offset(s, max_chars + 1)
        return s:sub(1, (p and p - 1) or #s)
    end
    local p = utf8.offset(s, max_chars - 2 + 1)
    return s:sub(1, (p and p - 1) or #s) .. '...'
end

-- Cache: single-GUI semantics with boolean dirty flag
-- Use GUIWindow:window_id() for stable identity across callbacks
local status = {
    workspaces = {},    -- sorted list of workspace names
    windows_by_ws = {}, -- ws_name -> { { id, gw, title }, ... }
    active_ws = '',     -- current active workspace name
    active_id = nil,    -- current active GUI window id
    -- render versioning: bump on changes; each window renders once per version
    version = 0,
    rendered = {},      -- [window_id] = version last rendered
    dirty = true,       -- legacy flag (kept for clarity)
}

-- ===== producers =====
local function mark_changed()
    status.version = (status.version or 0) + 1
    status.dirty = true
end

local function set_active(window)
    if not window then return end
    status.active_id = window:window_id()
    local mw = window:mux_window()
    status.active_ws = window:active_workspace() or (mw and mw:get_workspace()) or ''
    mark_changed()
end

local function resolve_window_title(gw, mw)
    if not gw then return '' end
    if not mw then
        local ok, got = pcall(function()
            return gw:mux_window()
        end)
        if not ok then return '' end
        mw = got
    end
    if not mw or not mw.get_title then return '' end
    local ok, got = pcall(function()
        return mw:get_title()
    end)
    return (ok and got) or ''
end

local function refresh_titles()
    local changed = false
    for _ws, wins in pairs(status.windows_by_ws) do
        for _, rec in ipairs(wins) do
            local title = resolve_window_title(rec.gw)
            if rec.title ~= title then
                rec.title = title
                changed = true
            end
        end
    end
    if changed then
        mark_changed()
    end
end

local function set_status()
    -- workspaces
    local names
    if wezterm.mux and wezterm.mux.get_workspace_names then
        local ok, list = pcall(wezterm.mux.get_workspace_names)
        if ok and type(list) == 'table' and #list > 0 then
            names = {}
            for _, n in ipairs(list) do table.insert(names, n) end
            table.sort(names)
        end
    end
    if not names then
        local seen, ws_list = {}, {}
        for _, gw in ipairs(wezterm.gui.gui_windows()) do
            local mw = gw:mux_window()
            local name = gw:active_workspace() or mw:get_workspace()
            if name and not seen[name] then
                seen[name] = true
                table.insert(ws_list, name)
            end
        end
        table.sort(ws_list)
        names = ws_list
    end
    status.workspaces = names or {}

    -- windows per workspace; store GUI window id for stable identity
    status.windows_by_ws = {}
    for _, ws in ipairs(status.workspaces) do
        status.windows_by_ws[ws] = {}
    end
    for _, gw in ipairs(wezterm.gui.gui_windows()) do
        local mw = gw:mux_window()
        local ws = gw:active_workspace() or mw:get_workspace()
        if ws then
            local t = status.windows_by_ws[ws]
            if not t then
                t = {}
                status.windows_by_ws[ws] = t
            end
            -- cache current title; it may change later, but this is cheap and avoids
            -- recomputing for every render when nothing changed.
            local title = resolve_window_title(gw, mw)
            table.insert(t, { id = gw:window_id(), gw = gw, title = title })
        end
    end

    mark_changed()
end

-- ===== consumer =====
local function current_workspace_index(active_ws)
    for i, name in ipairs(status.workspaces) do
        if name == active_ws then return i end
    end
    return 1
end

-- Render only: consume cache; no cache mutation except clearing dirty
local function render_from_cache(window)
    local wid = window:window_id()
    local gw = window
    local mw = gw:mux_window()
    local ws = status.active_ws ~= '' and status.active_ws or (gw:active_workspace() or mw:get_workspace() or '')

    -- Opportunistic consistency check: if window count changed but producers
    -- didn't fire (missed event), refresh cache now.
    local expected = 0
    for _, gw2 in ipairs(wezterm.gui.gui_windows()) do
        local mw2 = gw2:mux_window()
        local ws2 = gw2:active_workspace() or mw2:get_workspace()
        if ws2 == ws then expected = expected + 1 end
    end
    local current = #(status.windows_by_ws[ws] or {})
    if expected ~= current then
        set_status()
    end

    refresh_titles()

    if status.rendered[wid] == status.version then return end

    local active_id = status.active_id or wid
    local gw = window
    local mw = gw:mux_window()
    local ws = status.active_ws ~= '' and status.active_ws or (gw:active_workspace() or mw:get_workspace() or '')

    -- Workspace info
    local ws_idx = current_workspace_index(ws)
    local ws_text = string.format(' %s %d %s ', GLYPH_WORKSPACE, ws_idx, ellipsize_utf8(ws, 22))

    -- Windows in this workspace (records with id + gw)
    local wins = status.windows_by_ws[ws] or {}
    local active_index
    for i, rec in ipairs(wins) do
        if rec.id == active_id then
            active_index = i; break
        end
    end

    local cells = Cells:new()
    local ids = { 'ws', 'gap_ws' }
    cells
        :add_segment('ws', ws_text, colors.ws_block, attr(attr.intensity('Bold')))
        :add_segment('gap_ws', ' ')

    for i, rec in ipairs(wins) do
        local id = 'win_idx_' .. i
        -- window block: icon + index + title (utf8-safe ellipsis)
        local text = string.format(' %s %d %s ', GLYPH_WINDOW, i, ellipsize_utf8(rec.title or '', 24))
        local color = (active_index == i) and colors.win_active or colors.win_inactive
        cells:add_segment(id, text, color, attr(attr.intensity('Bold')))
        table.insert(ids, id)
        if i < #wins then
            local gap_id = 'gap_' .. i
            cells:add_segment(gap_id, ' ')
            table.insert(ids, gap_id)
        end
    end

    window:set_right_status(wezterm.format(cells:render(ids)))

    -- mark this window rendered for current version
    status.rendered[wid] = status.version
end

M.setup = function()
    -- Consumers: render from cache only
    wezterm.on('update-right-status', function(window, _pane)
        render_from_cache(window)
    end)
    wezterm.on('update-status', function(window, _pane)
        render_from_cache(window)
    end)

    -- Producers
    wezterm.on('window-focus-changed', function(window, _pane)
        set_active(window) -- also marks dirty
    end)
    wezterm.on('window-created', function(_window, _pane)
        set_status()
    end)
    wezterm.on('window-destroyed', function(_window, _pane)
        set_status()
    end)
    wezterm.on('window-config-reloaded', function(_window)
        set_status()
    end)
end

return M
