local wezterm = require('wezterm')
local colors = require('colors.custom')

-- Seeding random numbers before generating for use
-- Known issue with lua math library
-- see: https://stackoverflow.com/questions/20154991/generating-uniform-random-numbers-in-lua
math.randomseed(os.time())
math.random()
math.random()
math.random()

local GLOB_PATTERN = '*.{jpg,jpeg,png,gif,bmp,ico,tiff,pnm,dds,tga}'

---@class BackDrops
---@field current_idx number index of current image
---@field images string[] background images
---@field origin_images string[] background images
---@field acrylic_images string[] background images
---@field images_dir string directory of background images. Default is `wezterm.config_dir .. '/backdrops/'`
---@field focus_color string background color when in focus mode. Default is `colors.custom.background`
---@field mode number 0: image 1: acrylic_image 2: focus
local BackDrops = {}
BackDrops.__index = BackDrops

--- Initialise backdrop controller
---@private
function BackDrops:init()
    local inital = {
        current_idx = 1,
        images = {},
        images_dir = wezterm.config_dir .. '/backdrops/',
        focus_color = colors.background,
        focus_on = false,
    }
    local backdrops = setmetatable(inital, self)
    return backdrops
end

---Override the default `images_dir`
---Default `images_dir` is `wezterm.config_dir .. '/backdrops/'`
---
--- INFO:
---  This function must be invoked before `set_images()`
---
---@param path string directory of background images
function BackDrops:set_images_dir(path)
    self.images_dir = path
    if not path:match('/$') then
        self.images_dir = path .. '/'
    end
    return self
end

---MUST BE RUN BEFORE ALL OTHER `BackDrops` functions
---Sets the `images` after instantiating `BackDrops`.
---
--- INFO:
---   During the initial load of the config, this function can only invoked in `wezterm.lua`.
---   WezTerm's fs utility `glob` (used in this function) works by running on a spawned child process.
---   This throws a coroutine error if the function is invoked in outside of `wezterm.lua` in the -
---   initial load of the Terminal config.
function BackDrops:set_images()
    local all_files = wezterm.glob(self.images_dir .. GLOB_PATTERN)
    self.images = {}
    self.origin_images = {}
    self.acrylic_images = {}

    for _, file in ipairs(all_files) do
        if string.find(file, '%.acrylic%.') then
            table.insert(self.acrylic_images, file)
        else
            table.insert(self.origin_images, file)
        end
    end
    self.images = self.acrylic_images
    return self
end

---Override the default `focus_color`
---Default `focus_color` is `colors.custom.background`
---@param focus_color string background color when in focus mode
function BackDrops:set_focus(focus_color)
    self.focus_color = focus_color
    return self
end

---Create the `background` options with the current image
---@private
---@return table
function BackDrops:_create_origin_opts()
    self.images = self.origin_images
    return {
        {
            source = { File = self.images[self.current_idx] },
            horizontal_align = 'Center',
        },
        {
            source = { Color = colors.background },
            height = '120%',
            width = '120%',
            vertical_offset = '-10%',
            horizontal_offset = '-10%',
            opacity = 0.96,
        },
    }
end

---Create the `background` options with the current image with acrylic
---@private
---@return table
function BackDrops:_create_acrylic_opts()
    self.images = self.acrylic_images
    return {
        {
            source = { File = self.images[self.current_idx] },
            horizontal_align = 'Center',
        },
    }
end

---Create the `background` options for focus mode
---@private
---@return table
function BackDrops:_create_focus_opts()
    return {
        {
            source = { Color = self.focus_color },
            height = '120%',
            width = '120%',
            vertical_offset = '-10%',
            horizontal_offset = '-10%',
            opacity = 1,
        },
    }
end

---Create the `background` options with the current image
---@private
---@return table
function BackDrops:_create_opts()
    if self.mode == 0 then
        return self:_create_origin_opts()
    elseif self.mode == 1 then
        return self:_create_acrylic_opts()
    else
        return self:_create_focus_opts()
    end
end

---Override the current window options for background
---@private
---@param window any WezTerm Window see: https://wezfurlong.org/wezterm/config/lua/window/index.html
---@param background_opts table background option
function BackDrops:_set_opt(window, background_opts)
    window:set_config_overrides({
        background = background_opts,
        enable_tab_bar = window:effective_config().enable_tab_bar,
    })
end

---Set the initial options for `background`
---@param mode number? mode: 0: image 1: acrylic image 2: focus on
function BackDrops:initial_options(mode)
    mode = tonumber(mode) or 0
    assert(mode >= 0 and mode <= 2, 'BackDrops:initial_options - Expected mode to be 0, 1, or 2')
    self.mode = mode
    return self:_create_opts()
end

---Convert the `files` array to a table of `InputSelector` choices
---see: https://wezfurlong.org/wezterm/config/lua/keyassignment/InputSelector.html
function BackDrops:choices()
    local choices = {}
    for idx, file in ipairs(self.images) do
        table.insert(choices, {
            id = tostring(idx),
            label = file:match('([^/]+)$'),
        })
    end
    return choices
end

---Select a random background from the loaded `files`
---Pass in `Window` object to override the current window options
---@param window any? WezTerm `Window` see: https://wezfurlong.org/wezterm/config/lua/window/index.html
function BackDrops:random(window)
    self.current_idx = math.random(#self.images)

    if window ~= nil then
        self:_set_opt(window, self:_create_opts())
    end
end

---Cycle the loaded `files` and select the next background
---@param window any WezTerm `Window` see: https://wezfurlong.org/wezterm/config/lua/window/index.html
function BackDrops:cycle_forward(window)
    if self.current_idx == #self.images then
        self.current_idx = 1
    else
        self.current_idx = self.current_idx + 1
    end
    self:_set_opt(window, self:_create_opts())
end

---Cycle the loaded `files` and select the previous background
---@param window any WezTerm `Window` see: https://wezfurlong.org/wezterm/config/lua/window/index.html
function BackDrops:cycle_back(window)
    if self.current_idx == 1 then
        self.current_idx = #self.images
    else
        self.current_idx = self.current_idx - 1
    end
    self:_set_opt(window, self:_create_opts())
end

---Set a specific background from the `files` array
---@param window any WezTerm `Window` see: https://wezfurlong.org/wezterm/config/lua/window/index.html
---@param idx number index of the `files` array
function BackDrops:set_img(window, idx)
    if idx > #self.images or idx < 0 then
        wezterm.log_error('Index out of range')
        return
    end

    self.current_idx = idx
    self:_set_opt(window, self:_create_opts())
end

---Toggle the mode
---@param window any WezTerm `Window` see: https://wezfurlong.org/wezterm/config/lua/window/index.html
function BackDrops:toggle_backdrop_mode(window)
    if self.mode == 0 then
        self.mode = 1
    elseif self.mode == 1 then
        self.mode = 2
    else
        self.mode = 0
    end

    self:_set_opt(window, self:_create_opts())
end

return BackDrops:init()
