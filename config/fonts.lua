local wezterm = require('wezterm')
local platform = require('utils.platform')

local en_font = {
    family = 'SauceCodePro Nerd Font',
    weight = 'Light',
    freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}

local cn_font_macos = {
    family = 'PingFang SC', -- Fallback font for better Chinese display on Mac
    weight = 'Light',
    scale = 1,
    freetype_load_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    freetype_render_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}

local cn_font_window = {
    family = 'PingFang SC', -- Fallback font for better Chinese display on Mac
    weight = 'Light',
    scale = 1,
    freetype_load_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    freetype_render_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}

local cn_font_linux = {
    family = 'PingFang SC', -- Fallback font for better Chinese display on Mac
    weight = 'Light',
    scale = 1,
    freetype_load_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    freetype_render_target = 'HorizontalLcd', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}

local cn_font;

if platform.is_mac then
    cn_font = cn_font_macos
elseif platform.is_win then
    cn_font = cn_font_window
else
    cn_font = cn_font_linux
end

local font = wezterm.font_with_fallback({ en_font, cn_font })

-- local font_size = platform.is_mac and 14 or 14
local font_size = 13

return {
    font = font,
    font_size = font_size,

    --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
    use_cap_height_to_scale_fallback_fonts = true,
}
