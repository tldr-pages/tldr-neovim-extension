local Config = require("tldr.config")
local Window = require("tldr.window")
local Glow = require("tldr.glow")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")

local M = {}
local platforms = {"common", "linux", "windows", "osx", "openbsd", "sunos", "android"}

-- Get all the entries
-- @return table
local function get_entries()
	local entries = {}
	local dir = Config.get("cache_dir") .. "/pages/"

	for _, platform in ipairs(platforms) do
		local fullpath = dir .. platform .. "/"

		for _, file in ipairs(vim.fn.readdir(fullpath)) do
			local name = string.sub(file, 1, -4)

			table.insert(entries, name)
		end
	end

	return entries
end

-- Get the tldr page
-- @param args string
-- @return string|nil
local function get_tldr_file(...)
	-- concat all arguments with -
	local filename = table.concat({...}, "-") .. ".md"

	local lang = Config.get("preferred_language") or "en"
	local pages_dir = lang == "en" and "pages" or "pages." .. lang

	local parent = Config.get("cache_dir") .. "/" .. pages_dir .. "/"

	for _, value in ipairs(platforms) do
		local fullpath = parent .. value .. "/" .. filename

		if vim.fn.filereadable(fullpath) == 1 then
			return fullpath
		end
	end

	pages_dir = "pages"
	parent = Config.get("cache_dir") .. "/" .. pages_dir .. "/"

	for _, value in ipairs(platforms) do
		local fullpath = parent .. value .. "/" .. filename

		if vim.fn.filereadable(fullpath) == 1 then
			return fullpath
		end
	end

	return nil
end

-- Open telescope to search for a page
-- @return void
function M.open_telescope()
	local entries = get_entries()
	pickers.new({}, {
		prompt_title = "TLDR",
		finder = finders.new_table {
			results = entries,
			entry_maker = function(entry)
				return {
					value = entry,
					display = " " .. entry,
					ordinal = entry,
				}
			end,
		},
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				M.show(selection.value)
			end)

			return true
		end,
	}):find()
end

function M.show(...)
	if ... == nil then
		M.open_telescope()
		return
	end

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
