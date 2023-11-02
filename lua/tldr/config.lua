local M = {}

local defaults = {
	cache_dir = os.getenv("HOME") .. "/.cache/tldr-nvim",
	repo_url = "https://github.com/tldr-pages/tldr.git",
	glow = vim.fn.exepath("glow"),
	theme = "dark",
	window = {
		relative = "editor",
		style = "minimal",
		width = 100,
		height = 30,
		row = 3,
		col = 35,
		focusable = true,
		border = "single",
	}
}

-- Get default config
-- @return table
function M.getConfig()
	return defaults
end

-- Get a config value
-- @param key string
-- @return any
function M.get(key)
	return defaults[key]
end

-- Set a config value
-- @param key string
-- @param value any
-- @return nil
function M.set(key, value)
	defaults[key] = value
end

return M

