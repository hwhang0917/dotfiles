local M = {}

local local_defaults = {
    theme = "rose-pine",
    transparent = true,
}

local _local_config
function M.local_config()
    if not _local_config then
        local ok, cfg = pcall(require, "runfridge.local")
        _local_config = vim.tbl_extend("force", local_defaults, ok and cfg or {})
    end
    return _local_config
end

function M.is_git_repo()
    return vim.fn.finddir(".git", ".;") ~= ""
end

function M.notify(title, text, level, timeout)
    level = level or "info"
    timeout = timeout or 1000

    local message = title and (title .. ": " .. text) or text
    local ok, noice = pcall(require, "noice")
    if ok then
        noice.notify(text, level, {
            title = title,
            timeout = timeout,
        })
    else
        local vim_level = vim.log.levels.INFO
        if level == "error" then
            vim_level = vim.log.levels.ERROR
        elseif level == "warn" then
            vim_level = vim.log.levels.WARN
        end
        vim.notify(message, vim_level)
    end
end

local transparent = false

function M.apply_transparency(color)
    vim.cmd.colorscheme(color or vim.g.colors_name)
    local groups = { "Normal", "NormalFloat", "NormalNC", "NvimTreeNormal", "NvimTreeNormalFloat", "NvimTreeNormalNC" }
    for _, group in ipairs(groups) do
        vim.api.nvim_set_hl(0, group, { bg = "none" })
    end
    vim.api.nvim_set_hl(0, "LineNr", { fg = "gray" })
    transparent = true
end

function M.toggle_transparency(color)
    if transparent then
        vim.cmd.colorscheme(color or vim.g.colors_name)
        transparent = false
    else
        M.apply_transparency(color)
    end
end

function M.get_os()
    local os_name = vim.uv.os_uname().sysname:lower()
    if os_name:find("windows") then
        return "windows"
    elseif os_name:find("linux") then
        return "linux"
    elseif os_name:find("darwin") then
        return "macos"
    else
        return "unknown"
    end
end

return M
