local Config = require("tldr.config")
local Window = require("tldr.window")
local Glow = require("tldr.glow")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")

local M = {}
local platforms = {"common", "linux", "windows", "osx", "sunos", "android", "openbsd", "freebsd", "netbsd"}
local platform_icons = {
	android = "",
	common = "",
	freebsd = "",
	linux = "",
	openbsd = "",
	netbsd = "󰈾", -- icon don't exist in NerdFonts
	osx = "",
	sunos = "",
	windows = "",
}

-- Get all the entries
-- @return table
local function get_entries()
	local entries = {}
	local dir = Config.get("cache_dir") .. "/pages/"

	for _, platform in ipairs(platforms) do
		local fullpath = dir .. platform .. "/"

		for _, file in ipairs(vim.fn.readdir(fullpath)) do
			local name = string.sub(file, 1, -4)
			table.insert(entries, {name = name, icon = platform_icons[platform]})
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
	
	if #entries == 0 then
		vim.notify("❌ No TLDR pages found. Please run :TldrUpdate to download them.", vim.log.levels.ERROR)
		return
	end
	
	local picker = pickers.new({}, {
		prompt_title = "📚 TLDR Pages (" .. #entries .. " available)",
		results_title = "Commands",
		finder = finders.new_table {
			results = entries,
			entry_maker = function(entry)
				return {
					value = entry.name,
					display = entry.icon .. "  " .. entry.name,
					ordinal = entry.name,
				}
			end,
		},
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, _)
			actions.select_default:replace(function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				vim.notify("📖 Opening TLDR page for: " .. selection.value, vim.log.levels.INFO)
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
		local search_term = table.concat({...}, "-")
		vim.notify("❌ TLDR page not found for: '" .. search_term .. "'", vim.log.levels.ERROR)
		vim.notify("💡 Try ':Tldr' without arguments to browse available pages", vim.log.levels.INFO)
		return
	end

	local lines = {}
	for line in io.lines(filename) do
		table.insert(lines, line)
	end

	if Glow.isExecutable() then
		lines = Glow.render(lines)
	else
		vim.notify("⚠️  Glow renderer not found", vim.log.levels.WARN)
		local input = vim.fn.input({
			prompt = "📦 Install glow for better rendering? [Y/n]: "
		})
		
		if input:lower() == "y" or input:lower() == "yes" or input == "" then
			vim.notify("🔄 Installing glow...", vim.log.levels.INFO)
			Glow.install()
			-- Check if installation was successful
			if Glow.isExecutable() then
				vim.notify("✅ Glow installed successfully! Rendering page...", vim.log.levels.INFO)
				lines = Glow.render(lines)
			else
				vim.notify("❌ Glow installation may have failed. Displaying plain text.", vim.log.levels.WARN)
			end
		else
			vim.notify("📝 Displaying plain text (install glow for better rendering)", vim.log.levels.INFO)
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
