return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = true,
	config = function()
		require("rose-pine").setup({
			highlight_groups = {
				StatusLine = { fg = "iris", bg = "iris", blend = 10 },
				StatusLineNC = { fg = "subtle", bg = "surface" },
				DiffAdd = { bg = "#3fb950", fg = "#191724", blend = 100 },
				DiffDelete = { bg = "#f85149", fg = "#191724", blend = 100 },
				DiffChange = { bg = "#26233A", blend = 100 },
				DiffText = { bg = "#F6C177", fg = "#191724", bold = true, blend = 100 },
			},
		})
	end,
}
