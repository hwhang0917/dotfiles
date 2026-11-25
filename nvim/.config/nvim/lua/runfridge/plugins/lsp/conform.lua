return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "jq" },
				graphql = { "prettier" },
				markdown = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				vue = { "prettier" },
                go = { "gopls", "goimports" },
			},
			format_on_save = function(bufnr)
				-- jdtls / kotlin_lsp would reformat whole files via lsp_fallback; leave JVM code alone
				local skip = { java = true, kotlin = true }
				if skip[vim.bo[bufnr].filetype] then
					return
				end
				return {
					timeout_ms = 10000,
					lsp_fallback = true,
				}
			end,
		})
	end,
}
