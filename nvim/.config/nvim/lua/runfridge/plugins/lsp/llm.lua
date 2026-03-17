local cfg = require("runfridge.utils").local_config()

if not cfg.llm_enabled then
    return {}
end

return {
    "huggingface/llm.nvim",
    init = function()
        local orig = vim.lsp.util.make_position_params
        vim.lsp.util.make_position_params = function(window, position_encoding)
            position_encoding = position_encoding
                or vim.lsp.get_clients({ bufnr = 0 })[1].offset_encoding
                or "utf-16"
            return orig(window, position_encoding)
        end
    end,
    opts = {
        model = cfg.llm_model,
        backend = cfg.llm_backend,
        url = cfg.llm_url,
        tokens_to_clear = { "<|endoftext|>" },
        request_body = {
            options = {
                temperature = 0.2,
                top_p = 0.95,
                num_predict = 60,
            },
        },
        fim = {
            enabled = true,
            prefix = "<|fim_prefix|>",
            middle = "<|fim_middle|>",
            suffix = "<|fim_suffix|>",
        },
        debounce_ms = 100,
        accept_keymap = "<C-c>",
        dismiss_keymap = "<S-Tab>",
    },
}
