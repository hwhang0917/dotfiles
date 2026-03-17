return {
	"folke/tokyonight.nvim",
	lazy = true,
	config = function()
		require("tokyonight").setup({
			style = "moon",
			terminal_colors = true,
			styles = {
				comments = { italic = true },
				keywords = { italic = true },
			},
		})
	end,
}
