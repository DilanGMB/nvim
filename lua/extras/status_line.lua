local dvi = require("nvim-web-devicons")
-- local Job = require("plenary.job")
local M = {}

-- setup status line
M.status_line = function ()
  local parts = {
    "%#StatusLineModes#",
    [=[[ %{luaeval("require('extras.status_line').get_mode()")} ]]=],
    "%*",
    [[%{luaeval("require('extras.status_line').get_git_info()")}]],

    -- [[ %<%{luaeval("require('extras.status_line').file_or_lsp_status()")} %m%r%= ]],
    [[ %<%{luaeval("require('extras.status_line').get_filename()")} %m%r%= ]],

    "%=",
    "%#StatusLineWarn#",
    "%{&ff != 'unix' ? '['.&ff.']' : ''}",
    "%*",

    "%#StatusLineWarn#",
    "%{(&fenc != 'utf-8' && &fenc != '') ? '['.&fenc.']' : ''}",
    "%*",

    [[%{luaeval("require('extras.status_line').get_diagnostic_status()")}]],
    [[%{luaeval("require('extras.status_line').dap_status()")}]],
    "[%l:%v]%y",
  }

  return table.concat(parts, "")
end

-- get diagnostic status
M.get_diagnostic_status = function ()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.tbl_isempty(vim.lsp.buf_get_clients(bufnr))
  if clients then return "" end

  local items = { "ERROR", "WARN", "HINT", "INFO" }
  local result = {}

  if #vim.diagnostic.get(0) < 1 then return "" end
  for _, item in pairs(items) do
    local element_num = #vim.diagnostic.get(0, {
      severity = vim.diagnostic.severity[item]
    })
    if element_num > 0 then
      table.insert(result, string.format("%s:%d",
        item:sub(1, 1), element_num))
    end
  end

  local str_result = table.concat(result, " ")
  if vim.fn.len(str_result) > 0 then
    return string.format("[%s]", str_result)
  else return ""
  end
end

-- get name of the current mode
M.get_mode = function ()
  local mode = vim.api.nvim_get_mode().mode
  local modes_map = {
    n  = 'Normal',     no = 'N·OpPd',     v  = 'Visual',      V  = 'V·Line',
    c  = 'Cmmand',     s  = 'Select',     S  = 'S·Line',      t  = 'Term',
    i  = 'Insert',     ic = 'ICompl',     R  = 'Rplace',      Rv = 'VRplce',
    rm = 'More  ',     cv = 'Vim Ex',     ce = 'Ex (r)',      r  = 'Prompt',
    [''] = 'V·Blck', ['r?'] = 'Cnfirm', ['!']  = 'Shell ', [''] = 'S·Block',
  }
  return modes_map[mode] or mode
end

-- format uri to make readable file names
M.format_uri = function (uri)
  if vim.startswith(uri, "jdt://") then
    local package = uri:match('contents/[%a%d._-]+/([%a%d._-]+)') or ''
    local class = uri:match('contents/[%a%d._-]+/[%a%d._-]+/([%a%d$]+).class') or ''
    return string.format('%s::%s', package, class)
  else
    local regular_name = vim.fn.fnamemodify(vim.uri_to_fname(uri), ':.')
    return regular_name == "/" and "[No Name]" or regular_name
  end
end

M.get_filename = function ()
  local bufnr = vim.api.nvim_get_current_buf()
  local fname = M.format_uri(vim.uri_from_bufnr(bufnr))
  return string.format("%s %s",
    dvi.get_icon(vim.fn.fnamemodify(fname, ":e")) or "", fname)
end

-- get file name or lsp status
M.file_or_lsp_status = function ()
  local messages = vim.lsp.util.get_progress_messages()
  local mode = M.get_mode()

  if mode ~= 'Normal' or vim.tbl_isempty(messages) then
    return M.get_filename()
  end

  local percentage
  local result = {}

  for _, msg in pairs(messages) do
    if msg.message then
      table.insert(result, msg.title .. ': ' .. msg.message)
    else
      table.insert(result, msg.title)
    end
    if msg.percentage then
      percentage = math.max(percentage or 0, msg.percentage)
    end
  end

  if percentage then
    return string.format('(%d%%) %s', percentage, table.concat(result, ', '))
  else
    return table.concat(result, ', ')
  end
end

-- get dap status
function M.dap_status()
  local ok, dap = pcall(require, 'dap')
  if not ok then return '' end
  local status = dap.status()
  if status == '' then return '' end
  return string.format("[DAP: %s]", status)
end

-- get git info (requires fugitive)
M.get_git_info = function ()
  local is_git_dir = vim.fn["FugitiveIsGitDir"]()
  if is_git_dir < 1 then return '' end
  local current_branch = vim.fn["FugitiveHead"]()
  return string.format("[ %s]", current_branch)
end

return M
