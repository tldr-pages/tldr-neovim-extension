local Cache = require("tldr.cache")
local Config = require("tldr.config")

local M = {}

function M.update()
	vim.notify("Updating TLDR Pages...", vim.log.levels.INFO)
	Cache.update()
	vim.notify("TLDR Pages updated", vim.log.levels.INFO)
end

-- Setup tldr-nvim
-- @param opts table
-- @return nil
function M.setup(opts)
	if opts then
		vim.tbl_deep_extend("force", Config.getConfig(), opts)
	end

	if not Cache.exists() then
		local answer = vim.fn.input("TLDR Pages not found. Do you want to download them? (Y/n)")

		if answer == "Y" or answer == "y" or answer == "" then
			vim.notify("Downloading TLDR Pages...", vim.log.levels.INFO)
			Cache.download()
		else
			vim.notify("TLDR: Failed to download TLDR Pages", vim.log.levels.ERROR)
		end
	else
		if Config.get("auto_update") then
			Cache.update()
		end
	end

	vim.cmd [[ command! -nargs=* Tldr lua require("tldr.tldr").show(<f-args>) ]]
	vim.cmd [[ command! -nargs=* TldrUpdate lua require("tldr").update() ]]
end

return M

