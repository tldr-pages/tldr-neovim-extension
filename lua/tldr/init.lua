local Cache = require("tldr.cache")
local Config = require("tldr.config")

local M = {}

function M.update()
	vim.notify("🔄 Updating TLDR pages in the background...", vim.log.levels.INFO)
	Cache.update()
end

M.show = require("tldr.tldr").show

-- Setup tldr-nvim
-- @param opts table
-- @return nil
function M.setup(opts)
	if opts then
		Config.merge(opts)
	end

	if not Cache.exists() then
		local answer = vim.fn.input({
			prompt = "📥 TLDR pages not found. Download them now? [Y/n]: ",
		})

		if answer:lower() == "y" or answer:lower() == "yes" or answer == "" then
			vim.notify("📥 Downloading TLDR pages in the background...", vim.log.levels.INFO)
			Cache.download()
		else
			vim.notify("❌ TLDR: Cannot function without TLDR pages.", vim.log.levels.WARN)
		end
	else
		if Config.get("auto_update") then
			Cache.update()
		end
	end

	vim.cmd [[ command! -nargs=* Tldr lua require("tldr").show(<f-args>) ]]
	vim.cmd [[ command! -nargs=* TldrUpdate lua require("tldr").update() ]]
end

return M

