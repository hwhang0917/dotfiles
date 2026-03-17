local utils = require("runfridge.utils")
local cfg = utils.local_config()

local theme = cfg.theme or "rose-pine"
local transparent = cfg.transparent

-- Statusline
local os_icons = { Windows_NT = "", Linux = "", Darwin = "" }
local os_icon = os_icons[vim.uv.os_uname().sysname] or "💀"
vim.opt.laststatus = 2
vim.opt.statusline = " %f %m %= %l:%c " .. os_icon .. " "

-- Apply colorscheme after lazy.nvim loads the theme plugin
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    once = true,
    callback = function()
        require("lazy").load({ plugins = { theme } })
        vim.cmd.colorscheme(theme)
        if transparent then
            utils.apply_transparency(theme)
        end
    end,
})

-- Toggle transparency
vim.keymap.set("n", "<leader>tt", function()
    utils.toggle_transparency(theme)
end, { noremap = true, silent = true })
