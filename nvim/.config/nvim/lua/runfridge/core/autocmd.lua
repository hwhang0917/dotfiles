local api = vim.api

--- Remove all trailing whitespace on save
-- local TrimWhiteSpaceGrp = api.nvim_create_augroup("TrimWhiteSpaceGrp", { clear = true })
-- api.nvim_create_autocmd("BufWritePre", {
-- 	command = [[:%s/\s\+$//e]],
-- 	group = TrimWhiteSpaceGrp,
-- })

-- Highlight on yank
api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Claude Code writes its settings files with 2-space indentation; conform's jq
-- formatter follows shiftwidth, so match it to avoid reformat churn on save
api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	pattern = "*/.claude/settings*.json",
	command = "setlocal shiftwidth=2 softtabstop=2",
})
