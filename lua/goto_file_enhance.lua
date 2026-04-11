local M = {}

local function trim_token(s)
  if not s or s == "" then
    return s
  end
  s = s:gsub("^['\"`<(]+", "")
  s = s:gsub("[,.;:>%)%]\"'`]+$", "")
  s = s:gsub("^file://", "")
  return s
end

local function parse_ref(raw)
  raw = trim_token(raw)

  -- path#L10-L20
  local p0, l0s, l0e = raw:match("^(.-)#L(%d+)%-(%d+)$")
  if p0 and l0s and l0e then
    return p0, tonumber(l0s), 1, tonumber(l0e)
  end

  local p, l = raw:match("^(.-)#L(%d+)$")
  if p and l then
    return p, tonumber(l), 1
  end

  -- path:10-20
  local pr, lrs, lre = raw:match("^(.-):(%d+)%-(%d+)$")
  if pr and lrs and lre then
    return pr, tonumber(lrs), 1, tonumber(lre)
  end

  local p2, l2, c2 = raw:match("^(.-):(%d+):(%d+)$")
  if p2 and l2 and c2 then
    return p2, tonumber(l2), tonumber(c2)
  end

  local p3, l3 = raw:match("^(.-):(%d+)$")
  if p3 and l3 then
    return p3, tonumber(l3), 1
  end

  return raw, nil, nil, nil
end

local function resolve_path(path)
  if not path or path == "" then
    return nil
  end
  path = vim.fn.expand(path)
  return vim.fn.fnamemodify(path, ":p")
end

local function join_with_prev_line(path)
  if not path or path == "" then
    return path
  end
  if path:find("[/\\]") then
    return path
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  if row <= 1 then
    return path
  end

  local prev = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1] or ""
  prev = trim_token(vim.trim(prev))
  local prefix = prev:match("([%w%._%-%/%\\]+[/\\])$")
  if prefix then
    return prefix .. path
  end

  return path
end

local function find_other_win()
  local cur = vim.api.nvim_get_current_win()
  local wins = vim.api.nvim_tabpage_list_wins(0)

  if #wins <= 1 then
    return nil
  end

  local alt = vim.fn.win_getid(vim.fn.winnr("#"))
  if alt > 0 and vim.api.nvim_win_is_valid(alt) and alt ~= cur then
    return alt
  end

  for _, w in ipairs(wins) do
    if w ~= cur then
      return w
    end
  end
  return nil
end

local function open_file_safely(path, line, col, line_end, opts)
  local mode = opts.open_mode or "smart" -- smart|reuse|split|vsplit|tabedit

  if mode == "split" or mode == "vsplit" or mode == "tabedit" then
    vim.cmd(mode .. " " .. vim.fn.fnameescape(path))
  else
    local w = find_other_win()
    if w then
      vim.api.nvim_set_current_win(w)
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    else
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    end
  end

  if line then
    vim.api.nvim_win_set_cursor(0, { line, math.max((col or 1) - 1, 0) })
  end

  if line and line_end and line_end >= line then
    vim.cmd("normal! V")
    vim.api.nvim_win_set_cursor(0, { line_end, 0 })
  end
end

function M.goto_file_enhance(user_opts)
  local opts = vim.tbl_deep_extend("force", {
    open_mode = "reuse",
  }, vim.g.goto_file_enhance_opts or {}, user_opts or {})

  local token = vim.fn.expand("<cWORD>")
  if not token or token == "" then
    token = vim.fn.expand("<cfile>")
  end
  token = trim_token(token)

  local path, line, col, line_end = parse_ref(token)

  path = join_with_prev_line(path)

  path = resolve_path(path)
  if not path then
    return false, "path_unrecognized"
  end

  if vim.fn.isdirectory(path) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    return true, "opened_dir"
  end

  if vim.fn.filereadable(path) ~= 1 then
    return false, "file_not_found"
  end

  open_file_safely(path, line, col, line_end, opts)
  return true, "opened_file"
end

return M
