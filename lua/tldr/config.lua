local M = {}

-- Calculate centered window position
-- @param width number Window width
-- @param height number Window height
-- @return table Position configuration
local function calculate_center(width, height)
    local screen_width = vim.o.columns
    local screen_height = vim.o.lines

    -- Calculate center position
    local col = math.floor((screen_width - width) / 2)
    local row = math.floor((screen_height - height) / 2)

    -- Ensure minimum margins
    col = math.max(col, 2)
    row = math.max(row, 1)

    return {
        col = col,
        row = row
    }
end

local defaults = {
    cache_dir = os.getenv("HOME") .. "/.cache/tldr-nvim",
    repo_url = "https://github.com/tldr-pages/tldr.git",
    glow = vim.fn.exepath("glow") or os.getenv("HOME") .. "/.local/bin/glow",
    theme = "dark",
    auto_update = true,
    preferred_language = "en",
    window = {
        relative = "editor",
        style = "minimal",
        width = 100,
        height = 30,
        col = 0,
        row = 0,
        focusable = true,
        border = "single"
    }
}

local position = calculate_center(defaults.window.width, defaults.window.height)
defaults.window.col = position.col
defaults.window.row = position.row

-- Get default config
-- @return table
function M.getConfig()
    return defaults
end

function M.merge(opts)
    if not opts or type(opts) ~= "table" then
        return
    end

    if opts.window and opts.window.width and opts.window.height and not opts.window.col and not opts.window.row then
        local position = calculate_center(opts.window.width, opts.window.height)
        opts.window.col = position.col
        opts.window.row = position.row
    end

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
