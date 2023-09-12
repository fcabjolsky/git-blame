local Job = require 'plenary.job'

M = {}

M.config = M.config or {}

local function extractTextInParentheses(inputString)
    local startPos, endPos = inputString:find("%b()")

    if startPos then
        return inputString:sub(startPos + 1, endPos - 1)
    end
end

M.setup = function(config)
    if not M.config.ns then
        M.config.ns = vim.api.nvim_create_namespace('git-utils-blame')
    end
end

local function pre_run()
    M.bufnr = vim.fn.bufnr()
    M.linenr = tostring(vim.fn.line('.'))
end

local function clean()
    vim.api.nvim_buf_clear_namespace(M.bufnr, M.config.ns, 0, -1)
    M.running = false
end

local function on_stdout(line)
    if line ~= nil then
        M.out = extractTextInParentheses(line)
    end
end

local function on_exit()
    if M.out == nil then
        return
    end
    vim.schedule(function()
        vim.api.nvim_buf_set_extmark(M.bufnr, M.config.ns, M.linenr - 1, 0, {
            virt_text = { { M.out } }
        })
        vim.defer_fn(function()
            if M.running then
                clean()
            end
        end, 5000)
    end)
end

M.blame = function()
    M.setup()
    pre_run()

    local range = M.linenr .. ',' .. M.linenr
    local currentFilePath = vim.api.nvim_buf_get_name(0)
    if M.running then
        clean()
    end

    M.running = true
    Job:new({
        command = 'git',
        args = {
            'blame',
            currentFilePath,
            '-L',
            range
        },
        cwd = vim.fn.expand('%:p:h'),
        on_stdout = function(_, out_line)
            on_stdout(out_line)
        end,
        on_exit = function()
            on_exit()
        end,
    }):sync()
end

return M
