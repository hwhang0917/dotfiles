return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = true,
	config = function()
		require("rose-pine").setup({
			highlight_groups = {
				StatusLine = { fg = "iris", bg = "iris", blend = 10 },
				StatusLineNC = { fg = "subtle", bg = "surface" },
			},
		})
	end,
}
