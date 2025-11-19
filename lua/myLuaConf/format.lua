require("lze").load({
	{
		"conform.nvim",
		for_cat = "format",
		keys = {
			{ "<leader>FF", desc = "[F]ormat [F]ile" },
		},
		after = function(plugin)
			local conform = require("conform")

			conform.setup({
				-- This matches your old NixVim config
				format_on_save = {
					lsp_fallback = true, -- Try LSP first, then external formatters
					timeout_ms = 500,
				},
				notify_on_error = true,

				formatters_by_ft = {
					-- These are FALLBACK formatters (same as your old config)
					cpp = { "clang-format" },
					c = { "clang-format" },
					nix = { "nixfmt" },
					lua = { "stylua" }, -- Fallback for Lua if LSP fails
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>FF", function()
				conform.format({
					lsp_fallback = true, -- Use LSP first
					async = true,
					timeout_ms = 500,
				})
			end, { desc = "[F]ormat [F]ile" })

			-- Also add the format-on-save from your old config
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function(args)
					conform.format({
						lsp_fallback = true,
						async = false,
						timeout_ms = 500,
					})
				end,
			})
		end,
	},
})
