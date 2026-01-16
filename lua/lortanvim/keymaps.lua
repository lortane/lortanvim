local keymap = vim.keymap.set

-- [[ General Utility ]]
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")
keymap({ "n", "v", "x" }, "<C-a>", "gg0vG$", { desc = "Select all" })

-- Better scroll and search centering
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")

-- Move lines in visual mode
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })

-- Deal with word wrap (move by screen line unless count is given)
keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Buffer Navigation ]]
keymap("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = "Previous buffer" })
keymap("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = "Last buffer" })
keymap("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- [[ Clipboard Operations ]]
keymap({ "v", "x", "n" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
keymap({ "n", "v", "x" }, "<leader>Y", '"+yy', { desc = "Yank line to clipboard" })
keymap({ "n", "v", "x" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })
keymap("i", "<C-p>", "<C-r><C-p>+", { desc = "Paste from clipboard in insert mode" })
keymap("x", "<leader>P", '"_dP', { desc = "Paste over selection (keep register)" })

-- [[ Diagnostics ]]
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- [[ Fix Common Typos ]]
vim.cmd([[command! W w]])
vim.cmd([[command! Wq wq]])
vim.cmd([[command! WQ wq]])
vim.cmd([[command! Q q]])
