local M = {}

local repoUrl = "https://github.com/tldr-pages/tldr.git"
local cacheFolder = os.getenv("HOME") .. "/.cache/tldr.nvim"

function M.download()
	local gitCloneCommand = "git clone " .. repoUrl .. " " .. cacheFolder
	local _, exitCode, _ = os.execute(gitCloneCommand)

	return exitCode
end

function M.exists()
	local f = io.open(cacheFolder .. "/.git/config", "r")

	if f then
		io.close(f)
		return true
	else
		return false
	end
end

function M.update()
	local gitPullCommand = "git -C " .. cacheFolder .. " pull"
	local _, exitCode, _ = os.execute(gitPullCommand)

	return exitCode
end

local function _clear(dir)
	local dirObj = vim.loop.fs_scandir(dir)

	if not dirObj then
		return
	end

	for entry, entryType in vim.loop.fs_scandir_next, dirObj do
		if entry ~= "." and entry ~= ".." then
			local path = dir .. "/" .. entry

			if entryType == "directory" then
				_clear(path)
			else
				vim.loop.fs_unlink(path)
			end
		end
	end

	vim.loop.fs_rmdir(dir)
end

function M.clear()
	_clear(cacheFolder)
end

function M.getCacheFolder()
	return cacheFolder
end

return M
