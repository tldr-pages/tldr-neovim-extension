local M = {}

local repoUrl = "https://github.com/tldr-pages/tldr.git"
local cacheFolder = os.getenv("HOME") .. "/.cache/tldr.nvim"

local uv = vim.loop

function M.download()
	local gitCloneCommand = "git"
    local gitCloneArgs = { "clone", repoUrl, cacheFolder }

	local handle, pid = uv.spawn(gitCloneCommand, {
		args = gitCloneArgs,
		stdio = { nil, nil, nil },
	}, function(code, _)
		if code == 0 then
			print("TLDR: Successfully downloaded tldr pages")
		else
			print("TLDR: Failed to download tldr pages")
		end
	end)

	uv.unref(handle)
	return pid
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
	local gitPullCommand = "git"
	local gitPullArgs = { "pull" }

	local handle, pid = uv.spawn(gitPullCommand, {
		args = gitPullArgs,
		cwd = cacheFolder,
		stdio = { nil, nil, nil },
	}, function(code, _)
		if code ~= 0 then
			print("TLDR: Failed to update tldr pages")
		end
	end)

	uv.unref(handle)
	return pid
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
