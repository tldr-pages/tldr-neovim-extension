local Config = require("tldr.config")

local M = {}

function M.isExecutable()
	return vim.fn.executable(Config.get("glow")) == 1
end

-- Get the latest release URL
-- @return string|nil
local function get_latest_release()
	local cmd = "curl --silent \"https://api.github.com/repos/charmbracelet/glow/releases/latest\" | grep '\"tag_name\":' | sed -E 's/.*\"v([^\\\"]+)\".*/\\1/'"
	local handle = io.popen(cmd)
	if handle == nil then
		return nil
	end
	local result = handle:read("*a")
	if result == nil then
		return nil
	end
	handle:close()
	result = result:gsub("\n", "")
	return result
end

-- Download the latest release
-- @return nil
function M.install()
	local latest_release = get_latest_release()
	if latest_release == nil then
		vim.notify("Error: Could not get latest release", vim.log.levels.ERROR)
		return
	end

	local cmd = "curl -L -o /tmp/glow.tar.gz https://github.com/charmbracelet/glow/releases/download/v" .. latest_release .. "/glow_Linux_x86_64.tar.gz"

	vim.fn.system(cmd)
	vim.fn.system("tar -xzf /tmp/glow.tar.gz -C /tmp")
	vim.fn.system("mv /tmp/glow " .. Config.get("glow"))
	vim.fn.system("chmod +x " .. Config.get("glow"))
	vim.fn.system("rm /tmp/glow.tar.gz")
end

local function tmp_file()
	local tmp_dir = vim.fn.tempname()
	vim.fn.mkdir(tmp_dir, "p")
	return tmp_dir .. "/tldr.md"
end

-- Render markdown with glow
-- @param lines table list of lines
-- @return table rendered lines
function M.render(lines)
	local tmp = tmp_file()
	local file = io.open(tmp, "w")

	if file == nil then
		vim.notify("Error: Could not open file " .. tmp, vim.log.levels.ERROR)
		return lines
	end

	for _, line in ipairs(lines) do
		file:write(line .. "\n")
	end
	file:close()

	local result = vim.fn.systemlist(Config.get("glow") .. " --width=100 -s " .. Config.get("theme") .." " .. tmp)
	vim.fn.delete(tmp)

	return result
end

return M

