{
  description = "lortanvim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      inherit (inputs.nixCats) utils;
      luaPath = ./.;
      forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;

      dependencyOverlays = [ (utils.standardPluginOverlay inputs) ];

      categoryDefinitions =
        { pkgs, categories, ... }:
        {
          # 1. Binary Dependencies (Software installed on your system)
          lspsAndRuntimeDeps = {
            general = with pkgs; [
              ripgrep
              fd
              universal-ctags
            ];
            nix = with pkgs; [
              nixd
              nixfmt
            ];
            lua = with pkgs; [
              lua-language-server
              stylua
            ];
            cpp = with pkgs; [ clang-tools ];
          };

          # 2. Plugins that load IMMEDIATELY
          startupPlugins = {
            general = with pkgs.vimPlugins; [
              lze
              lzextras # Lazy loading engine
              plenary-nvim # Library for many plugins
              nvim-web-devicons # Icons
              (nvim-notify.overrideAttrs (_: {
                doCheck = false;
              }))
            ];
            themer =
              with pkgs.vimPlugins;
              if categories.colorscheme == "onedark" then onedark-nvim else kanagawa-nvim;
          };

          # 3. Plugins that load LATER (via lze)
          optionalPlugins = {
            treesitter = with pkgs.vimPlugins; [
              nvim-treesitter.withAllGrammars
              nvim-treesitter-textobjects
            ];
            lsp = with pkgs.vimPlugins; [
              nvim-lspconfig
              blink-cmp
              blink-compat
              luasnip
              fidget-nvim
              lazydev-nvim
              comment-nvim
              nvim-surround
              colorful-menu-nvim
            ];
            ui = with pkgs.vimPlugins; [
              lualine-nvim
              gitsigns-nvim
              which-key-nvim
              indent-blankline-nvim
              todo-comments-nvim
            ];
            tools = with pkgs.vimPlugins; [
              oil-nvim
              telescope-nvim
              telescope-fzf-native-nvim
              undotree
              # vim-sleuth
            ];
          };

          # 4. Environment / Wrapper (Cleaned up)
          environmentVariables = { };
          extraWrapperArgs = { };
        };

      packageDefinitions = {
        lortanvim =
          { ... }:
          {
            settings = {
              wrapRc = true;
              configDirName = "lortanvim";
              aliases = [
                "nv"
                "nvim"
                "lvim"
              ];
            };
            categories = {
              general = true;
              lsp = true;
              treesitter = true;
              ui = true;
              tools = true;
              nix = true;
              lua = true;
              cpp = true;
              themer = true;
              colorscheme = "kanagawa";
            };
          };
      };

      defaultPackageName = "lortanvim";
    in
    forEachSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        nixCatsBuilder = utils.baseBuilder luaPath {
          inherit nixpkgs system dependencyOverlays;
        } categoryDefinitions packageDefinitions;
        defaultPackage = nixCatsBuilder defaultPackageName;
      in
      {
        packages = utils.mkAllWithDefault defaultPackage;
        devShells.default = pkgs.mkShell {
          name = defaultPackageName;
          packages = [ defaultPackage ];
        };
      }
    )
    // {
      nixosModules.default = utils.mkNixosModules {
        inherit
          nixpkgs
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          ;
        moduleNamespace = [ "lortanvim" ];
        defaultPackageName = "lortanvim";
      };
      homeModules.default = utils.mkHomeModules {
        inherit
          nixpkgs
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          ;
        moduleNamespace = [ "lortanvim" ];
        defaultPackageName = "lortanvim";
      };
      # Simplified: Just export the essentials
      inherit utils;
    };
}
