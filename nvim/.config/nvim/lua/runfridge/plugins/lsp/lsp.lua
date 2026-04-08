return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    dependencies = {
        {
            "williamboman/mason.nvim",
            build = function()
                pcall(vim.cmd, "MasonUpdate")
            end,
        },
        { "williamboman/mason-lspconfig.nvim" },
        { "hrsh7th/nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp" },
        { "L3MON4D3/LuaSnip" },
        { "rafamadriz/friendly-snippets" },
        { "hrsh7th/cmp-buffer" },
        { "hrsh7th/cmp-path" },
        { "hrsh7th/cmp-cmdline" },
        { "saadparwaiz1/cmp_luasnip" },
    },
    config = function()
        local cmp = require("cmp")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        local luasnip = require("luasnip")

        require("mason").setup()

        local servers = {
            "lua_ls", "ts_ls", "eslint", "tailwindcss", "yamlls",
            "rust_analyzer", "jsonls", "html", "dockerls", "vue_ls",
        }

        require("mason-lspconfig").setup()

        -- Vue language server path (static path per Mason v2 docs)
        local vue_language_server_path = vim.fn.stdpath("data")
            .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

        vim.lsp.config("*", {
            capabilities = cmp_nvim_lsp.default_capabilities(),
        })

        vim.lsp.config("ts_ls", {
            init_options = {
                plugins = {
                    {
                        name = "@vue/typescript-plugin",
                        location = vue_language_server_path,
                        languages = { "vue" },
                    },
                },
            },
            filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
            on_attach = function(client)
                if vim.bo.filetype == "vue" then
                    client.server_capabilities.semanticTokensProvider.full = false
                end
            end,
        })

        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    runtime = { version = "LuaJIT" },
                    diagnostics = { globals = { "vim" } },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                        checkThirdParty = false,
                    },
                    telemetry = { enable = false },
                },
            },
        })

        vim.lsp.enable(servers)

        vim.diagnostic.config({
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "E",
                    [vim.diagnostic.severity.WARN] = "W",
                    [vim.diagnostic.severity.HINT] = "H",
                    [vim.diagnostic.severity.INFO] = "I",
                },
            },
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(ev)
                local opts = { buffer = ev.buf, remap = false }
                vim.keymap.set("n", "gr", function()
                    require("telescope.builtin").lsp_references()
                end, vim.tbl_extend("force", opts, { desc = "LSP Goto Reference" }))
                vim.keymap.set("n", "gd", function()
                    vim.lsp.buf.definition()
                end, vim.tbl_extend("force", opts, { desc = "LSP Goto Definition" }))
                vim.keymap.set("n", "K", function()
                    vim.lsp.buf.hover()
                end, vim.tbl_extend("force", opts, { desc = "LSP Hover" }))
                vim.keymap.set("n", "<leader>vws", function()
                    vim.lsp.buf.workspace_symbol()
                end, vim.tbl_extend("force", opts, { desc = "LSP Workspace Symbol" }))
                vim.keymap.set("n", "<leader>vd", function()
                    vim.diagnostic.setloclist()
                end, vim.tbl_extend("force", opts, { desc = "LSP Show Diagnostics" }))
                vim.keymap.set("n", "[d", function()
                    vim.diagnostic.jump({ count = -1, float = true })
                end, vim.tbl_extend("force", opts, { desc = "Previous Diagnostic" }))
                vim.keymap.set("n", "]d", function()
                    vim.diagnostic.jump({ count = 1, float = true })
                end, vim.tbl_extend("force", opts, { desc = "Next Diagnostic" }))
                vim.keymap.set("n", "<leader>vca", function()
                    vim.lsp.buf.code_action()
                end, vim.tbl_extend("force", opts, { desc = "LSP Code Action" }))
                vim.keymap.set("n", "<leader>vrn", function()
                    vim.lsp.buf.rename()
                end, vim.tbl_extend("force", opts, { desc = "LSP Rename" }))
                vim.keymap.set("n", "<F2>", function()
                    vim.lsp.buf.rename()
                end, vim.tbl_extend("force", opts, { desc = "LSP Rename" }))
                vim.keymap.set("i", "<C-h>", function()
                    vim.lsp.buf.signature_help()
                end, vim.tbl_extend("force", opts, { desc = "LSP Signature Help" }))
            end,
        })

        local cmp_kinds = {
            Text = "  ",
            Method = "  ",
            Function = "  ",
            Constructor = "  ",
            Field = "  ",
            Variable = "  ",
            Class = "  ",
            Interface = "  ",
            Module = "  ",
            Property = "  ",
            Unit = "  ",
            Value = "  ",
            Enum = "  ",
            Keyword = "  ",
            Snippet = "  ",
            Color = "  ",
            File = "  ",
            Reference = "  ",
            Folder = "  ",
            EnumMember = "  ",
            Constant = "  ",
            Struct = "  ",
            Event = "  ",
            Operator = "  ",
            TypeParameter = "  ",
        }

        require("luasnip.loaders.from_vscode").lazy_load()

        local cmp_select = { behavior = cmp.SelectBehavior.Select }
        ---@diagnostic disable-next-line: redundant-parameter
        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            sources = {
                { name = "nvim_lsp" },
                { name = "luasnip", keyword_length = 2 },
                { name = "buffer",  keyword_length = 3 },
                { name = "path" },
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
                ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
                ["<C-y>"] = cmp.mapping.confirm({ select = true }),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-f>"] = cmp.mapping(function(fallback)
                    if luasnip.jumpable(1) then
                        luasnip.jump(1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<C-b>"] = cmp.mapping(function(fallback)
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            }),
            formatting = {
                format = function(_, vim_item)
                    vim_item.kind = cmp_kinds[vim_item.kind] or ""
                    return vim_item
                end,
            },
        })

        cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },
            },
        })

        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "path" },
            }, {
                {
                    name = "cmdline",
                    option = {
                        ignore_cmds = { "Man", "!" },
                    },
                },
            }),
        })
    end,
}
