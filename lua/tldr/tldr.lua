local Config = require("tldr.config")
local Window = require("tldr.window")
local Glow = require("tldr.glow")

local M = {}

-- Get the tldr page
-- @param args string
-- @return string|nil
local function get_tldr_file(...)
	-- concat all arguments with -
	local filename = table.concat({...}, "-") .. ".md"

	-- TODO: add support for other languages
	local parent = Config.get("cache_dir") .. "/pages/"
	local dirs = {"common", "linux", "windows", "osx", "openbsd", "sunos", "android"}

	for _, value in ipairs(dirs) do
		local fullpath = parent .. value .. "/" .. filename

		if vim.fn.filereadable(fullpath) == 1 then
			return fullpath
		end
	end

	return nil
end


function M.show(...)
	local filename = get_tldr_file(...)
	if filename == nil then
		vim.notify("TLDR: Page not found", vim.log.levels.ERROR)
		return
	end

	local lines = {}
	for line in io.lines(filename) do
		table.insert(lines, line)
	end

	if Glow.isExecutable() then
		lines = Glow.render(lines)
	end

	local win = Window.new()

	-- glow requires a terminal to display renedered text properly
	term = vim.api.nvim_open_term(vim.api.nvim_win_get_buf(win), {})
	vim.api.nvim_chan_send(term, table.concat(lines, "\r\n"))
end


return M
