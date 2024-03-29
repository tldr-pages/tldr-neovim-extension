local M = {}

local defaults = {
	cache_dir = os.getenv("HOME") .. "/.cache/tldr-nvim",
	repo_url = "https://github.com/tldr-pages/tldr.git",
	glow = vim.fn.exepath("glow"),
	theme = "dark",
	auto_update = true,
	preferred_language = "en",
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

if defaults.glow == "" then
	defaults.glow = os.getenv("HOME") .. "/.local/bin/glow"
end

-- Get default config
-- @return table
function M.getConfig()
	return defaults
end

function M.merge(opts)
	defaults = vim.tbl_deep_extend("force", defaults, opts)
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

