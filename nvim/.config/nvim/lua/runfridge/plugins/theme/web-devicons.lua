return {
	"nvim-tree/nvim-web-devicons",
	lazy = true,
	config = function()
		require("nvim-web-devicons").setup({
            default = true,
			override = {
				js = {
					icon = "",
                    color = "#f1e05a",
                    cterm_color = "185",
					name = "Js",
				},
				ts = {
					icon = "",
					color = "#519aba",
					cterm_color = "74",
					name = "Ts",
				},
				css = {
					icon = "",
					color = "#3d8fc6",
					cterm_color = "74",
					name = "Css",
				},
			},
		})
	end,
}
