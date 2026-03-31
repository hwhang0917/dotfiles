-- Utilities
Add("runfridge.plugins.utility.arena")
Add("runfridge.plugins.utility.harpoon")
Add("runfridge.plugins.utility.nerdy")
Add("runfridge.plugins.utility.nvim-tree")
Add("runfridge.plugins.utility.telescope")
Add("runfridge.plugins.utility.tpope")
Add("runfridge.plugins.utility.zen")
-- Git
Add("runfridge.plugins.git.fugitive")
Add("runfridge.plugins.git.gitsigns")
-- Theme
Add("runfridge.plugins.theme.catppuccin")
Add("runfridge.plugins.theme.rosepine")
Add("runfridge.plugins.theme.tokyonight")
Add("runfridge.plugins.theme.web-devicons")
Add("runfridge.plugins.theme.yugen")
-- Interface
Add("runfridge.plugins.interface.color-highlighter")
Add("runfridge.plugins.interface.illuminate")
Add("runfridge.plugins.interface.indent-blankline")
Add("runfridge.plugins.interface.noice")
-- Code Syntax & LSP
Add("runfridge.plugins.lsp.conform")
Add("runfridge.plugins.lsp.lsp")
Add("runfridge.plugins.lsp.treesitter")
Add("runfridge.plugins.lsp.vim-go")
-- Misc
Add("runfridge.plugins.misc.wakatime")
Add("runfridge.plugins.misc.plenary")
Add("runfridge.plugins.misc.bloat")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(PLUGIN_SPECS, {
    checker = { enabled = false },
    install = { colorscheme = { "rose-pine", "habamax" } },
})
