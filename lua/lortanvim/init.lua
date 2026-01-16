-- Set the colorscheme from your Flake, defaulting to kanagawa
vim.cmd.colorscheme(nixCats("colorscheme") or "kanagawa")
-----------------------------------------------------------------------------
-- LZE Handlers Registration
-- These allow 'lze' to use nixCats categories and manage LSP loading.
-----------------------------------------------------------------------------
local lze = require("lze")

-- Enables the 'for_cat' field in your plugin specs
lze.register_handlers(require("nixCatsUtils.lzUtils").for_cat)

-- Enables advanced LSP loading logic within plugin specs
lze.register_handlers(require("lzextras").lsp)

-----------------------------------------------------------------------------
-- Core Configuration
-----------------------------------------------------------------------------
require("lortanvim.options")
require("lortanvim.keymaps")
require("lortanvim.plugins")

-----------------------------------------------------------------------------
-- Category-Specific Modules
-- These only load if the corresponding category is 'true' in your flake.
-----------------------------------------------------------------------------

-- Load LSP configuration if the 'lsp' category is enabled
if nixCats("lsp") then
	require("lortanvim.lsp")
end
