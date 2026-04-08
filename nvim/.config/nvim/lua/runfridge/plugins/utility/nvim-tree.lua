return {
	"nvim-tree/nvim-tree.lua",
	cmd = "NvimTreeFindFileToggle",
	keys = {
		{ "<C-n>", function() require("nvim-tree.api").tree.toggle() end, desc = "Toggle NvimTree" },
	},
	config = function()
		require("nvim-tree").setup({
			hijack_cursor = true,
			disable_netrw = true,
			view = {
				number = true,
				relativenumber = true,
				cursorline = true,
				width = 30,
				side = "right",
			},
			renderer = {
				add_trailing = true,
				group_empty = true,
				indent_markers = {
					enable = true,
				},
			},
			git = {
				enable = true,
				timeout = 1000,
			},
			modified = {
				enable = true,
			},
			filters = {
				git_ignored = false,
				dotfiles = false,
				git_clean = false,
				no_buffer = false,
				custom = { "^\\.git$", "node_modules" },
				exclude = {},
			},
		})
	end,
}
