local telescope_keys = {
	{ "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help Tags" },
	{ "<C-g>", function()
		require("telescope.builtin").grep_string({ search = vim.fn.input("🔍 Grep >") })
	end, desc = "Grep String" },
	{ "<C-f>", function()
		require("telescope.builtin").current_buffer_fuzzy_find(
			require("telescope.themes").get_dropdown({
				windblend = 10,
				previewer = false,
				layout_config = { width = 0.7 },
			})
		)
	end, desc = "Buffer Fuzzy Find" },
	{ "<C-p>", function()
		if require("runfridge.utils").is_git_repo() then
			require("telescope.builtin").git_files()
		else
			require("telescope.builtin").find_files()
		end
	end, desc = "Find Files" },
	{ "<leader>nerdy", function()
		require("telescope").load_extension("nerdy")
		require("telescope").extensions.nerdy.nerdy()
	end, desc = "Nerdy Icons" },
}

if require("runfridge.utils").is_git_repo() then
	table.insert(telescope_keys, {
		"<leader>gc", function() require("telescope.builtin").git_commits() end, desc = "Git Commits",
	})
	table.insert(telescope_keys, {
		"<leader>gbc", function() require("telescope.builtin").git_bcommits() end, desc = "Git Buffer Commits",
	})
end

return {
	"nvim-telescope/telescope.nvim",
	version = "*",
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = vim.fn.executable("make") == 1 and "make"
				or vim.fn.executable("cmake") == 1
					and "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release"
				or nil,
			enabled = vim.fn.executable("make") == 1 or vim.fn.executable("cmake") == 1,
		},
	},
	cmd = "Telescope",
	keys = telescope_keys,
	config = function()
		require("telescope").setup({
			defaults = {
				disable_devicons = false,
				path_display = { "truncate" },
			},
		})
		pcall(require("telescope").load_extension, "noice")
		pcall(require("telescope").load_extension, "nerdy")
	end,
}
