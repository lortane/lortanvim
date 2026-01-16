local lze = require("lze")
local catUtils = require("nixCatsUtils")

-----------------------------------------------------------------------------
-- Performance Utilities (FT Fallback)
-----------------------------------------------------------------------------
local old_ft_fallback = lze.h.lsp.get_ft_fallback()
lze.h.lsp.set_ft_fallback(function(name)
	local lspcfg = nixCats.pawsible({ "allPlugins", "opt", "nvim-lspconfig" })
		or nixCats.pawsible({ "allPlugins", "start", "nvim-lspconfig" })
	if lspcfg then
		local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
		if not ok then
			ok, cfg = pcall(dofile, lspcfg .. "/lua/lspconfig/configs/" .. name .. ".lua")
		end
		return (ok and cfg or {}).filetypes or {}
	else
		return old_ft_fallback(name)
	end
end)

-----------------------------------------------------------------------------
-- The Shared on_attach Function
-----------------------------------------------------------------------------
local on_attach = function(client, bufnr)
	local nmap = function(keys, func, desc)
		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. (desc or "") })
	end

	-- Core Mappings
	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")

	-- Telescope Integration
	if nixCats("general.telescope") then
		local builtin = require("telescope.builtin")
		nmap("gr", function()
			builtin.lsp_references()
		end, "[G]oto [R]eferences")
		nmap("gI", function()
			builtin.lsp_implementations()
		end, "[G]oto [I]mplementation")
		nmap("<leader>ds", function()
			builtin.lsp_document_symbols()
		end, "[D]oc [S]ymbols")
		nmap("<leader>ws", function()
			builtin.lsp_dynamic_workspace_symbols()
		end, "[W]orkspace [S]ymbols")
	end

	-- Workspace Management
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	-- User Command
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end

-----------------------------------------------------------------------------
-- Server Configurations (LZE Load)
-----------------------------------------------------------------------------
lze.load({
	-- Base LSP Config Engine
	{
		"nvim-lspconfig",
		for_cat = "lsp",
		on_require = { "lspconfig" },
		lsp = function(plugin)
			require("lspconfig")[plugin.name].setup(vim.tbl_extend("force", {
				on_attach = on_attach,
			}, plugin.lsp or {}))
		end,
	},

	-- Lua Support
	{
		"lazydev.nvim",
		for_cat = "lua",
		ft = "lua",
		after = function()
			require("lazydev").setup({
				library = {
					{ words = { "nixCats" }, path = (nixCats.nixCatsPath or "") .. "/lua" },
				},
			})
		end,
	},
	{
		"lua_ls",
		enabled = nixCats("lua"),
		lsp = {
			filetypes = { "lua" },
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					diagnostics = { globals = { "nixCats", "vim" }, disable = { "missing-fields" } },
					signatureHelp = { enabled = true },
					telemetry = { enabled = false },
				},
			},
		},
	},

	-- C/C++ Support
	{
		"clangd",
		for_cat = "cpp",
		lsp = {
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=never",
				"--completion-style=detailed",
				"--function-arg-placeholders",
				"--fallback-style=llvm",
			},
			init_options = {
				clangdFileStatus = true,
				usePlaceholders = true,
				completeUnimported = true,
				semanticHighlighting = true,
			},
		},
	},

	-- Nix Support (Nixd)
	{
		"nixd",
		enabled = catUtils.isNixCats and nixCats("nix"),
		lsp = {
			filetypes = { "nix" },
			settings = {
				nixd = {
					nixpkgs = {
						expr = nixCats.extra("nixdExtras.nixpkgs") or [[import <nixpkgs> {}]],
					},
					options = {
						nixos = { expr = nixCats.extra("nixdExtras.nixos_options") },
						["home-manager"] = { expr = nixCats.extra("nixdExtras.home_manager_options") },
					},
					formatting = { command = { "nixfmt" } },
					diagnostic = { suppress = { "sema-escaping-with" } },
				},
			},
		},
	},
})
