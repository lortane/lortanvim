local opt = vim.opt

-- [[ Editor Aesthetics & Behavior ]]
opt.list = false -- Don't show tabs/spaces as visible characters by default
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- Define how those chars look if enabled
opt.hlsearch = true -- Keep matches from the previous search highlighted
opt.inccommand = "split" -- Show a live preview of search/replace (substitute) in a split
opt.scrolloff = 10 -- Always keep at least 10 lines visible above/below the cursor
opt.breakindent = true -- Wrapped lines will maintain the same indent level as the original
opt.undofile = true -- Save undo history to a file so it persists after closing Neovim
opt.signcolumn = "yes" -- Always show the column for Git/LSP icons (prevents layout "flicker")
opt.updatetime = 250 -- How often (ms) to write swap file and trigger CursorHold event
opt.timeoutlen = 300 -- Time (ms) to wait for a mapped sequence to complete
opt.termguicolors = true -- Enable 24-bit RGB colors in the TUI
opt.mouse = "a" -- Enable mouse support in all modes
opt.clipboard = "unnamedplus" -- Use the system clipboard for all yanks/deletes
opt.completeopt = "menu,preview,noselect" -- Better behavior for the popup completion menu

-- [[ Numbers ]]
vim.wo.number = true -- Show line numbers
vim.wo.relativenumber = true -- Show line numbers relative to the current cursor position

-- [[ Indentation & Tabs ]]
opt.cpoptions:append("I") -- Don't reset autoindent when joining lines
opt.expandtab = true -- Use spaces instead of tab characters
opt.tabstop = 2 -- One tab character looks like 2 spaces
opt.shiftwidth = 2 -- Pressing '>' or auto-indenting uses 2 spaces
opt.shiftround = true -- Round indent to the nearest multiple of shiftwidth
opt.smartindent = true -- Make indenting "smart" (e.g., adds indent after a bracket)
opt.autoindent = true -- Copy indent from the current line when starting a new one

-- [[ Search Case ]]
opt.ignorecase = true -- Case-insensitive search...
opt.smartcase = true -- ...unless the search query contains a capital letter

-- [[ Netrw Settings ]] (Built-in file explorer)
vim.g.netrw_liststyle = 0 -- Standard list view
vim.g.netrw_banner = 0 -- Hide the massive help banner at the top of the explorer

-----------------------------------------------------------------------------
-- [[ Autocommands ]]
-- These are "Event Listeners" that run code when something happens.
-----------------------------------------------------------------------------

-- Disable auto-commenting on a new line
-- (Prevents Neovim from adding a '#' or '//' automatically when you hit Enter)
vim.api.nvim_create_autocmd("FileType", {
	desc = "remove formatoptions",
	callback = function()
		vim.opt.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Highlight the text briefly when you "yank" (copy) it
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight on yank",
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})
