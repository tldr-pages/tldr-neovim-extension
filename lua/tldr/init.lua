local Cache = require("tldr.cache")
local Config = require("tldr.config")

local M = {}

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
		Cache.update()
	end

	vim.cmd [[ command! -nargs=* Tldr lua require("tldr.tldr").show(<f-args>) ]]
end

return M

