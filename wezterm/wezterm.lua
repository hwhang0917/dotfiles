-- This is needed for Wezterm API
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- =============================================================================
-- Shell
-- =============================================================================

if os.getenv("OS") == "Windows_NT" then
    config.default_prog = { "wsl", "--cd", "~" }
else
    config.default_prog = { "/usr/bin/zsh" }
end

-- =============================================================================
-- Rendering
-- =============================================================================

config.front_end = "WebGpu"

-- =============================================================================
-- Appearance
-- =============================================================================

config.color_scheme = "rose-pine-dawn"
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9

-- Rose Pine Dawn palette
local palette = {
    base = "#faf4ed",
    surface = "#fffaf3",
    overlay = "#f2e9e1",
    text = "#575279",
    muted = "#9893a5",
}

config.window_frame = {
    active_titlebar_bg = palette.base,
    inactive_titlebar_bg = palette.base,
    font = wezterm.font({ family = "FiraCode Nerd Font Ret", weight = "Bold" }),
    font_size = 11,
}

config.colors = {
    tab_bar = {
        background = palette.base,
        active_tab = {
            bg_color = palette.base,
            fg_color = palette.text,
            intensity = "Bold",
        },
        inactive_tab = {
            bg_color = palette.overlay,
            fg_color = palette.muted,
        },
        inactive_tab_hover = {
            bg_color = palette.overlay,
            fg_color = palette.text,
        },
        new_tab = {
            bg_color = palette.base,
            fg_color = palette.muted,
        },
        new_tab_hover = {
            bg_color = palette.overlay,
            fg_color = palette.text,
        },
    },
}

-- =============================================================================
-- Font
-- =============================================================================

config.font = wezterm.font_with_fallback({
    { family = "FiraCode Nerd Font Ret" },
    "D2Coding ligature",
    "Segoe UI Emoji",
})
config.harfbuzz_features = { "calt = 0", "clig = 0", "liga = 0" }
config.font_size = 12

-- =============================================================================
-- Tab title
-- =============================================================================

local function get_process_icon(process_name)
    if not process_name then
        return "󰣇"
    end

    local name = process_name:lower()

    if name:find("git") and name:find("bash") then
        return "   Windows"
    end

    if name:find("wsl") or name:find("zsh") or name:find("bash") then
        return "󰣇  WSL"
    end

    return "󰣇"
end

wezterm.on("format-tab-title", function(tab)
    local process_name = tab.active_pane.foreground_process_name or ""
    return { { Text = " " .. get_process_icon(process_name) } }
end)

-- =============================================================================
-- Keybindings
-- =============================================================================

config.keys = {
    -- Toggle transparency
    {
        key = "o",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window, _)
            local overrides = window:get_config_overrides() or {}
            if overrides.window_background_opacity == 1.0 then
                overrides.window_background_opacity = 0.9
            else
                overrides.window_background_opacity = 1.0
            end
            window:set_config_overrides(overrides)
        end),
    },
    -- Open Git Bash in new tab
    {
        key = "i",
        mods = "CTRL|SHIFT",
        action = wezterm.action.SpawnCommandInNewTab({
            args = { os.getenv("PROGRAMFILES") .. "\\Git\\bin\\bash.exe" },
        }),
    },
    -- Shift+Enter sends escape + carriage return
    {
        key = "Enter",
        mods = "SHIFT",
        action = wezterm.action({ SendString = "\x1b\r" }),
    },
}

return config
