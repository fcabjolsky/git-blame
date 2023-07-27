local Job = require 'plenary.job'

local function extractTextInParentheses(inputString)
    local startPos, endPos = inputString:find("%b()")

    if startPos then
        return inputString:sub(startPos + 1, endPos - 1)
    end
end

function GitBlameMe()
    local out
    local ns = vim.api.nvim_create_namespace('my_namespace')
    local bufnr = vim.fn.bufnr()
    local line = tostring(vim.fn.line('.'))
    local range = line..','..line

    local currentFilePath = vim.api.nvim_buf_get_name(0)

    Job:new({
        command = 'git',
        args = { 'blame', currentFilePath, '-L', range },
        cwd = vim.fn.expand('%:p:h'),
        on_stdout = function(_, b)
            if b ~= nil then
                out = extractTextInParentheses(b)
            end
        end,
        on_exit = function()
            if out ~= nil then
                vim.schedule(function()
                    vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
                        virt_text = { { out } }
                    })
                    vim.defer_fn(function()
                        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
                    end, 5000)
                end)
            end
        end,
    }):sync()
end
