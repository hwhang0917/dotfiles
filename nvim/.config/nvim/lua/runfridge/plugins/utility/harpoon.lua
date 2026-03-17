return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{ "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon Add" },
		{ "<C-e>", function()
			local harpoon = require("harpoon")
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, desc = "Harpoon Menu" },
		{ "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
		{ "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
		{ "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
		{ "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
		{ "<leader>5", function() require("harpoon"):list():select(5) end, desc = "Harpoon 5" },
		{ "<leader>6", function() require("harpoon"):list():select(6) end, desc = "Harpoon 6" },
		{ "<leader>7", function() require("harpoon"):list():select(7) end, desc = "Harpoon 7" },
		{ "<leader>8", function() require("harpoon"):list():select(8) end, desc = "Harpoon 8" },
		{ "<leader>9", function() require("harpoon"):list():select(9) end, desc = "Harpoon 9" },
		{ "<C-S-P>", function() require("harpoon"):list():prev() end, desc = "Harpoon Prev" },
		{ "<C-S-N>", function() require("harpoon"):list():next() end, desc = "Harpoon Next" },
	},
	config = function()
		require("harpoon"):setup({})
	end,
}
