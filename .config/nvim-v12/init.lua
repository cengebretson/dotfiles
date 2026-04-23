if vim.loader then
	vim.loader.enable()
end

require("core.keymaps")
require("core.options")
require("core.tabline")
require("plugins")
