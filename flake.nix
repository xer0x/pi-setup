{
  description = "Team Pi (pi.dev) configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";

    pi.url = "github:lukasl-dev/pi.nix";
    # pi.inputs.nixpkgs.follows = "nixpkgs";  # uncomment if compatible
  };

  nixConfig = {
    extra-substituters = [
      "https://pi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs = { self, nixpkgs, systems, pi, ... }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);

      # ── Shared team config (used by both `nix run` and the HM module) ──
      teamConfig = {
        rules = builtins.readFile ./rules.md;
        skills = [
          ./skills/nix-helper
          # add more shared skills here
        ];
        themes = [
          ./themes/team.json
          # add more themes here
        ];
        settings = {
          enableSkillCommands = true;
          theme = "team";

          # ── Pi packages (installed automatically on startup) ──
          packages = [
            "npm:pi-lmstudio"
            "npm:pi-mcp-adapter"
            # "npm:@foo/bar@1.0.0"
            # "git:github.com/user/repo@v1"
          ];
        };
        # extraArgs = [ "--provider" "anthropic" "--model" "claude-sonnet-4-20250514" ];
      };
    in
    {
      # ── `nix run .` — launches pi with team config baked in ──
      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          configured = pi.lib.mkCodingAgent {
            inherit pkgs;
            modules = [{
              pi.coding-agent = teamConfig;
            }];
          };
        in {
          default = configured.package;
          pi = configured.package;
        }
      );

      # ── Home-Manager module (import from your HM config) ──
      homeModules.default = { config, lib, pkgs, ... }: {
        imports = [ pi.homeModules.default ];

        programs.pi.coding-agent = {
          enable = true;
        } // teamConfig // {
          # ── Environment (HM-only, supports sops-nix) ──
          environment = {
            # ANTHROPIC_API_KEY.file = config.sops.secrets.anthropic-api-key.path;
            # OPENAI_API_KEY.file = config.sops.secrets.openai-api-key.path;
          };
        };
      };

      # ── Sanity check ──
      checks = forEachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          build = self.packages.${system}.default;
        }
      );
    };
}
