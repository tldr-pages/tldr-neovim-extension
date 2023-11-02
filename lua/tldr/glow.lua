local Config = require("tldr.config")

local M = {}

function M.isExecutable()
	return vim.fn.executable(Config.get("glow")) == 1
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

