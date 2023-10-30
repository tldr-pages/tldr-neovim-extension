local config = require("tldr.config")

local M = {}

-- Create a new window
-- @param opts table
-- @return winid number|nil
function M.new(opts)
	local c = config.get("window")

	if opts then
		vim.tbl_deep_extend("force", c, opts)
	end

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(bufnr, "filetype", "tldr")
	vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

	local winid = vim.api.nvim_open_win(bufnr, true, c)

	if winid == 0 then
		vim.notify("TLDR: Failed to open window", vim.log.levels.ERROR)
		return nil
	end

    return winid
end

-- Write lines to a window
-- @param winid number
-- @param lines table
-- @return nil
function M.write(winid, lines)
	local bufnr = vim.api.nvim_win_get_buf(winid)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

function M.lock_buffer(winid)
	local bufnr = vim.api.nvim_win_get_buf(winid)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

function M.close(winid)
	vim.api.nvim_win_close(winid, true)
end

return M

