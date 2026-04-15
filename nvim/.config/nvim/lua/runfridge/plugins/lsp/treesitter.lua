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

local is_musl = vim.fn.executable("ldd") == 1
    and vim.fn.system("ldd --version 2>&1"):lower():match("musl") ~= nil

return {
    "nvim-treesitter/nvim-treesitter",
    event = "FileType",
    build = not is_musl and ":TSUpdate" or false,
    config = function()
        require("nvim-treesitter").setup()
        if not is_musl then
            require("nvim-treesitter").install(parsers, { skip = { installed = true } })
        end

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
