return {
	"lukas-reineke/indent-blankline.nvim",
	event = "BufReadPost",
	main = "ibl",
	opts = {},
	config = function()
		require("ibl").setup({
			exclude = {
				filetypes = {
					"terminal",
					"dashboard",
					"lazy",
					"lspinfo",
					"TelescopePrompt",
					"TelescopeResults",
				},
			},
		})
	end,
}
