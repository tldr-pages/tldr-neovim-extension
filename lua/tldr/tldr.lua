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
	else
		local input = vim.fn.input("Glow is not installed. Do you want to install it? (y/n): ")
		if input == "y" then
			vim.notify("Installing glow...")
			Glow.install()
			vim.notify("Glow installed!")
			return
		else
			vim.notify("Glow is required for this plugin to work properly.\nPlease install it from https://github.com/charmbracelet/glow/releases/latest", vim.log.levels.ERROR)
			return
		end
	end

	local win = Window.new()
	if win == nil then
		vim.notify("Error: Could not create window", vim.log.levels.ERROR)
		return
	end

	Window.set_keymap(win, "n", "q", "<cmd>lua require('tldr.window').close(".. win .. ")<cr>", {noremap = true, silent = true})
	Window.set_keymap(win, "n", "<Esc>", "<cmd>lua require('tldr.window').close(".. win .. ")<cr>", {noremap = true, silent = true})

	-- glow requires a terminal to display renedered text properly
	local term = vim.api.nvim_open_term(vim.api.nvim_win_get_buf(win), {})
	vim.api.nvim_chan_send(term, table.concat(lines, "\r\n"))
end


return M
