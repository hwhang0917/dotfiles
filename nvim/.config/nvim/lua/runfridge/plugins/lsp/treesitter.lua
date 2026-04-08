local parsers = {
    "vimdoc",
    "javascript",
    "typescript",
    "c",
    "lua",
    "rust",
    "yaml",
    "json",
    "html",
    "css",
    "bash",
    "python",
    "go",
    "tsx",
    "markdown",
    "vue",
}

return {
    "nvim-treesitter/nvim-treesitter",
    event = "FileType",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup()
        require("nvim-treesitter").install(parsers, { skip = { installed = true } })

        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                pcall(vim.treesitter.start)
            end,
        })

        -- Start treesitter for buffers already loaded before this plugin initialized
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
                pcall(vim.treesitter.start, buf)
            end
        end
    end,
}
