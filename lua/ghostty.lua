local M = {}

---@class (exact) Options
---@field file_pattern? string The pattern to match the file name. If the file name matches the pattern, ghostty.nvim will run on save in that buffer.
---@field ghostty_cmd? string The ghostty executable to run.
---@field check_timeout? number The timeout in milliseconds for the check command. If the command takes longer than this it will be killed.

---@class (exact) OptionsStrict : Options
---@field file_pattern string
---@field ghostty_cmd string
---@field check_timeout number

---@type OptionsStrict
local default_config = {
    file_pattern = "*/ghostty/config",
    ghostty_cmd = "ghostty",
    check_timeout = 1000,
}

---@param msg string
local function error(msg)
    vim.api.nvim_err_writeln(" [ghostty.nvim]: " .. msg)
end

-- TODO: Move to utils
local function p(v)
    print(vim.inspect(v))
end

---@param str string
---@return { key: string, value: string }[]
local function parse_output(str)
    local result = {}
    for line in str:gmatch("[^\n]+") do
        local key, value = line:match("([^:]+):%s*(.*)")
        if key and value then
            table.insert(result, { key = key, value = value })
        end
    end
    return result
end

---@param str string
local function escape_pattern(str)
    return str:gsub("([%^$()%.[%]*+?%-])", "%%%1")
end

---@param lines string[]
---@param pattern string
local function find_pattern(lines, pattern)
    local escaped = escape_pattern(pattern)
    for line_number, line in ipairs(lines) do
        local match = line:match("^%s*" .. escaped .. "%s*=%s*.*")
        if match or line == pattern then
            return line_number - 1, 0 -- TODO: Set correct column
        end
    end
    return nil, nil
end

---@param opts OptionsStrict
---@param event any
local function validate_config(opts, event)
    local buf_lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)
    local obj = vim.system({ opts.ghostty_cmd, "+validate-config" }, { text = true })
        :wait(opts.check_timeout)

    local ns_id = vim.api.nvim_create_namespace("ghostty.nvim")
    if obj.code == 0 then
        vim.diagnostic.reset(ns_id, event.buf)
        return
    end

    local parsed = parse_output(obj.stdout)
    ---@type vim.Diagnostic[]
    local diagnostics = {}

    for _, diagnostic in ipairs(parsed) do
        local line_number, col_number = find_pattern(buf_lines, diagnostic.key)

        if line_number ~= nil and col_number ~= nil then
            ---@type vim.Diagnostic
            local new_diagnostic = {
                lnum = line_number,
                col = col_number,
                message = diagnostic.value,
                -- end_col = col_number + #diagnostic.key, -- TODO: Make sure this is correct
            }

            table.insert(diagnostics, new_diagnostic)
        end
    end

    vim.diagnostic.set(ns_id, event.buf, diagnostics)
end

---@param opts OptionsStrict
local function setup_autocmds(opts)
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("ghostty.nvim", { clear = true }),
        pattern = opts.file_pattern,
        callback = function(event)
            if vim.fn.executable(opts.ghostty_cmd) == 0 then
                error(
                    "Ghostty not installed. Make sure `"
                        .. opts.ghostty_cmd
                        .. "` is in your $PATH."
                )
                return
            end

            vim.defer_fn(function()
                validate_config(opts, event)
            end, 250)
        end,
    })
end

---@param opts OptionsStrict
local function init(opts)
    setup_autocmds(opts)
end

---@param opts? Options
M.setup = function(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", default_config, opts)

    init(opts)
end

return M
