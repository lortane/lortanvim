local lze = require("lze")

lze.load({
	-----------------------------------------------------------------------------
	-- LINTING (Nvim-lint)
	-----------------------------------------------------------------------------
	{
		"nvim-lint",
		for_cat = "lint",
		event = "FileType",
		after = function()
			local lint = require("lint")

			-- Add linters here as you install them via Nix
			lint.linters_by_ft = {
				-- Example: nix = { 'statix' },
			}

			-- Automatically run linter on save
			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
	-----------------------------------------------------------------------------
	-- FORMATTING (conform.nvim)
	-----------------------------------------------------------------------------
	{
		"conform.nvim",
		for_cat = "format",
		keys = {
			{ "<leader>f", desc = "[f]ormat file" },
		},
		after = function()
			local conform = require("conform")
			conform.setup({
				format_on_save = {
					lsp_fallback = true,
					timeout_ms = 500,
				},
				notify_on_error = true,
				formatters_by_ft = {
					cpp = { "clang-format" },
					c = { "clang-format" },
					nix = { "nixfmt" },
					lua = { "stylua" },
				},
			})

			vim.keymap.set({ "n", "v" }, "<leader>f", function()
				conform.format({ lsp_fallback = true, async = true, timeout_ms = 500 })
			end, { desc = "[f]ormat file" })
		end,
	},
	-----------------------------------------------------------------------------
	-- TREESITTER (nvim-treesitter)
	-----------------------------------------------------------------------------
	{
		"nvim-treesitter",
		for_cat = "treesitter", -- Matches the category in your flake
		event = "DeferredUIEnter",
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("nvim-treesitter-textobjects")
		end,
		after = function()
			-- Fix for the recent module name change in Treesitter
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				ok, configs = pcall(require, "nvim-treesitter.config")
			end

			if not ok then
				return
			end

			configs.setup({
				-- Enable better syntax highlighting
				highlight = { enable = true },
				-- We disable TS-based indenting because it's often buggy compared to Vim's
				indent = { enable = false },

				-- [[ Smart Selection ]]
				-- Allows you to select larger/smaller chunks of code with one key
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<c-space>", -- Start selecting
						node_incremental = "<c-space>", -- Select more
						node_decremental = "<M-space>", -- Select less (Alt+Space)
					},
				},

				-- [[ Text Objects ]]
				-- Advanced movement and selection
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- Automatically jump to the next object
						keymaps = {
							["af"] = "@function.outer", -- Select [a]round a [f]unction
							["if"] = "@function.inner", -- Select [i]nside a [f]unction
							["ac"] = "@class.outer", -- Select [a]round a [c]lass
							["ic"] = "@class.inner", -- Select [i]nside a [c]lass
						},
					},
					-- Swap parameters (e.g. move an argument in a function call)
					swap = {
						enable = true,
						swap_next = { ["<leader>a"] = "@parameter.inner" },
						swap_previous = { ["<leader>A"] = "@parameter.inner" },
					},
				},
			})
		end,
	},
	-----------------------------------------------------------------------------
	-- FUZZY FINDER (telescope.nvim)
	-----------------------------------------------------------------------------
	{
		"telescope.nvim",
		for_cat = "tools",
		cmd = { "Telescope", "LiveGrepGitRoot" },
		on_require = { "telescope" },
		keys = {
			-- Search shortcuts
			{
				"<leader>sf",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "[S]earch [F]iles",
			},
			{
				"<leader>sg",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "[S]earch by [G]rep",
			},
			{
				"<leader><leader>s",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "[ ] Find existing buffers",
			},
			{
				"<leader>s.",
				function()
					require("telescope.builtin").oldfiles()
				end,
				desc = "[S]earch Recent Files",
			},

			-- Git Root Search (using the helper defined below)
			{
				"<leader>sp",
				function()
					local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
					if vim.v.shell_error ~= 0 then
						require("telescope.builtin").live_grep()
					else
						require("telescope.builtin").live_grep({ search_dirs = { git_root } })
					end
				end,
				desc = "[S]earch git [P]roject root",
			},

			-- Advanced Searches
			{
				"<leader>/",
				function()
					require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
					}))
				end,
				desc = "[/] Fuzzily search in current buffer",
			},

			-- Housekeeping
			{
				"<leader>sh",
				function()
					require("telescope.builtin").help_tags()
				end,
				desc = "[S]earch [H]elp",
			},
			{
				"<leader>sk",
				function()
					require("telescope.builtin").keymaps()
				end,
				desc = "[S]earch [K]eymaps",
			},
			{
				"<leader>sr",
				function()
					require("telescope.builtin").resume()
				end,
				desc = "[S]earch [R]esume",
			},
			{
				"<leader>sd",
				function()
					require("telescope.builtin").diagnostics()
				end,
				desc = "[S]earch [D]iagnostics",
			},
		},
		load = function(name)
			vim.cmd.packadd(name)
			vim.cmd.packadd("telescope-fzf-native.nvim")
			vim.cmd.packadd("telescope-ui-select.nvim")
		end,
		after = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					mappings = {
						i = { ["<c-enter>"] = "to_fuzzy_refine" },
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			pcall(telescope.load_extension, "fzf")
			pcall(telescope.load_extension, "ui-select")
		end,
	},

	-----------------------------------------------------------------------------
	-- COMPLETION & SNIPPETS (blink.cmp)
	-----------------------------------------------------------------------------
	{
		"blink.cmp",
		for_cat = "lsp", -- Completion is core to the LSP experience
		event = "DeferredUIEnter",
		load = function(name)
			-- Load dependencies and their 'after' directories
			vim.cmd.packadd(name)
			vim.cmd.packadd("blink.compat")
			vim.cmd.packadd("cmp-cmdline")
			vim.cmd.packadd("luasnip")
			vim.cmd.packadd("colorful-menu.nvim")
		end,
		after = function()
			-- 1. Setup Snippets
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()
			luasnip.config.setup({})

			-- Keymap to cycle through snippet choices (M-n is Alt+n)
			vim.keymap.set({ "i", "s" }, "<M-n>", function()
				if luasnip.choice_active() then
					luasnip.change_choice(1)
				end
			end)

			-- 2. Setup Blink
			require("blink.cmp").setup({
				keymap = { preset = "default" },
				signature = { enabled = true },

				-- Use Colorful Menu for better looks
				completion = {
					menu = {
						draw = {
							treesitter = { "lsp" },
							components = {
								label = {
									text = function(ctx)
										return require("colorful-menu").blink_components_text(ctx)
									end,
									highlight = function(ctx)
										return require("colorful-menu").blink_components_highlight(ctx)
									end,
								},
							},
						},
					},
					documentation = { auto_show = true },
				},

				-- Command line completion (for : commands)
				cmdline = {
					enabled = true,
					sources = function()
						local type = vim.fn.getcmdtype()
						if type == "/" or type == "?" then
							return { "buffer" }
						end
						if type == ":" or type == "@" then
							return { "cmdline", "cmp_cmdline" }
						end
						return {}
					end,
				},

				-- Snippet integration logic
				snippets = {
					preset = "luasnip",
					active = function(filter)
						local snippet = require("luasnip")
						if snippet.in_snippet() and not require("blink.cmp").is_visible() then
							return true
						else
							if not snippet.in_snippet() and vim.fn.mode() == "n" then
								snippet.unlink_current()
							end
							return false
						end
					end,
				},

				-- Where suggestions come from
				sources = {
					default = { "lsp", "path", "snippets", "buffer", "omni" },
					providers = {
						path = { score_offset = 50 },
						lsp = { score_offset = 40 },
						snippets = { score_offset = 40 },
						cmp_cmdline = {
							name = "cmp_cmdline",
							module = "blink.compat.source",
							score_offset = -100,
							opts = { cmp_name = "cmdline" },
						},
					},
				},
			})
		end,
	},
	-----------------------------------------------------------------------------
	-- NOTIFICATIONS (nvim-notify)
	-----------------------------------------------------------------------------
	{
		"nvim-notify",
		for_cat = "ui",
		event = "DeferredUIEnter",
		after = function()
			local notify = require("notify")
			notify.setup({
				on_open = function(win)
					vim.api.nvim_win_set_config(win, { focusable = false })
				end,
			})
			vim.notify = notify

			-- Update your <Esc> keymap to also clear notifications
			vim.keymap.set("n", "<Esc>", function()
				vim.cmd("nohlsearch")
				notify.dismiss({ silent = true })
			end, { desc = "Dismiss notifications and clear highlights" })
		end,
	},

	-----------------------------------------------------------------------------
	-- FILE EXPLORER (oil.nvim)
	-----------------------------------------------------------------------------
	{
		"oil.nvim",
		for_cat = "tools",
		cmd = "Oil",
		keys = {
			{ "-", "<cmd>Oil<CR>", desc = "Open Parent Directory" },
			{ "<leader>-", "<cmd>Oil .<CR>", desc = "Open Project Root" },
		},
		after = function()
			-- Disable netrw (built-in explorer) to let Oil take over
			vim.g.loaded_netrwPlugin = 1

			require("oil").setup({
				default_file_explorer = true,
				view_options = { show_hidden = true },
				columns = { "icon", "permissions", "size" },
			})
		end,
	},
	-----------------------------------------------------------------------------
	-- UI: Statusline (Lualine)
	-----------------------------------------------------------------------------
	{
		"lualine.nvim",
		for_cat = "ui",
		event = "DeferredUIEnter",
		after = function()
			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = nixCats("colorscheme") or "kanagawa",
					component_separators = "|",
					section_separators = "",
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = {
						"branch",
						{ "diff", symbols = { added = " ", modified = " ", removed = " " } },
					},
					lualine_c = {
						{ "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " } },
					},
					lualine_x = { "filetype", "filename" },
				},
				tabline = {
					lualine_a = { "buffers" },
					lualine_z = { "tabs" },
				},
			})
		end,
	},

	-----------------------------------------------------------------------------
	-- UI: Visual Polish (Indent Blankline & Todo Comments)
	-----------------------------------------------------------------------------
	{
		"indent-blankline.nvim",
		for_cat = "ui",
		event = "DeferredUIEnter",
		after = function()
			require("ibl").setup()
		end,
	},
	{
		"todo-comments.nvim",
		for_cat = "ui",
		event = "DeferredUIEnter",
		keys = { { "<leader>st", "<cmd>TodoTelescope<CR>", desc = "[S]earch [T]ODOs" } },
		after = function()
			require("todo-comments").setup()
		end,
	},

	-----------------------------------------------------------------------------
	-- GIT: Gitsigns (Updated for nav_hunk)
	-----------------------------------------------------------------------------
	{
		"gitsigns.nvim",
		for_cat = "ui",
		event = "DeferredUIEnter",
		after = function()
			local gs = require("gitsigns")
			gs.setup({
				on_attach = function(bufnr)
					local function map(mode, l, r, desc)
						vim.keymap.set(mode, l, r, { buffer = bufnr, desc = "Git: " .. (desc or "") })
					end

					-- [[ Navigation ]]
					-- Using the new nav_hunk API
					map("n", "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.nav_hunk("next")
						end)
						return "<Ignore>"
					end, "Next Hunk")

					map("n", "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.nav_hunk("prev")
						end)
						return "<Ignore>"
					end, "Prev Hunk")

					-- [[ Actions ]]
					map("n", "<leader>gs", gs.stage_hunk, "Stage Hunk")
					map("n", "<leader>gr", gs.reset_hunk, "Reset Hunk")
					map("n", "<leader>gp", gs.preview_hunk, "Preview Hunk")
					map("n", "<leader>gb", function()
						gs.blame_line({ full = false })
					end, "Blame Line")
					map("n", "<leader>gd", gs.diffthis, "Diff This")
				end,
			})

			-- Custom colors for the signs in the gutter
			vim.cmd([[hi GitSignsAdd guifg=#04de21]])
			vim.cmd([[hi GitSignsChange guifg=#83fce6]])
			vim.cmd([[hi GitSignsDelete guifg=#fa2525]])
		end,
	},
	-----------------------------------------------------------------------------
	-- TOOLS: Undotree & Which-Key
	-----------------------------------------------------------------------------
	{
		"undotree",
		for_cat = "tools",
		cmd = "UndotreeToggle",
		keys = { { "<leader>U", "<cmd>UndotreeToggle<CR>", desc = "Undo Tree" } },
		before = function()
			vim.g.undotree_WindowLayout = 1
			vim.g.undotree_SplitWidth = 40
		end,
	},
	{
		"which-key.nvim",
		for_cat = "ui",
		event = "DeferredUIEnter",
		after = function()
			local wk = require("which-key")
			wk.setup({})
			wk.add({
				{ "<leader>c", group = "[c]ode" },
				{ "<leader>g", group = "[g]it" },
				{ "<leader>s", group = "[s]earch" },
				{ "<leader>w", group = "[w]orkspace" },
			})
		end,
	},

	-----------------------------------------------------------------------------
	-- EDITING: Surround & Comment
	-----------------------------------------------------------------------------
	{
		"nvim-surround",
		for_cat = "lsp",
		event = "DeferredUIEnter",
		after = function()
			require("nvim-surround").setup()
		end,
	},
	{
		"comment.nvim",
		for_cat = "lsp",
		event = "DeferredUIEnter",
		after = function()
			require("Comment").setup()
		end,
	},

	-----------------------------------------------------------------------------
	-- MARKDOWN
	-----------------------------------------------------------------------------
	{
		"markdown-preview.nvim",
		for_cat = "markdown",
		ft = "markdown",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview" },
		keys = { { "<leader>mt", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Preview" } },
		before = function()
			vim.g.mkdp_auto_close = 0
		end,
	},
	{
		"fidget.nvim",
		for_cat = "lsp",
		event = "LspAttach",
		after = function()
			require("fidget").setup({})
		end,
	},
})
