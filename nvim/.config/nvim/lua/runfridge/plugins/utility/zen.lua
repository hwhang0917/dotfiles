return {
	"folke/zen-mode.nvim",
	keys = {
		{ "<leader>zz", function()
			require("zen-mode").toggle({ window = { width = 0.95 } })
			vim.cmd("Gitsigns toggle_current_line_blame")
		end, desc = "Zen Mode" },
	},
	opts = {
		window = {
			backdrop = 0.95,
			options = {
				number = false,
				relativenumber = false,
			},
		},
	},
}
