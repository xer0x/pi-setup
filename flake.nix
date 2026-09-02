{
  description = "Team Pi (pi.dev) configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    pi.url = "github:lukasl-dev/pi.nix";
    # pi.inputs.nixpkgs.follows = "nixpkgs";  # uncomment if compatible
  };

  outputs = { self, nixpkgs, pi, ... }: {

    # ── Home-Manager module (import this from your HM config) ──
    homeModules.default = { config, lib, pkgs, ... }: {
      imports = [ pi.homeModules.default ];

      programs.pi.coding-agent = {
        enable = true;

        # ── Shared team rules ──
        rules = builtins.readFile ./rules.md;

        # ── Skills ──
        skills = [
          ./skills/nix-helper
          # add more shared skills here
        ];

        # ── Model catalog (optional) ──
        # models = ./models.json;

        # ── Default settings ──
        settings = {
          # model = "claude-sonnet-4-20250514";
          enableSkillCommands = true;
          theme = "dark";
        };

        # ── Environment ──
        environment = {
          # PI_OFFLINE.value = "1";          # useful in CI
          # ANTHROPIC_API_KEY.file = config.sops.secrets.anthropic-api-key.path;
          # OPENAI_API_KEY.file = config.sops.secrets.openai-api-key.path;
        };
      };
    };

    # ── Quick sanity check ──
    # nix flake check
    checks = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        module-eval = pkgs.runCommand "pi-setup-check" {} ''
          echo "pi-setup flake loads OK"
          touch $out
        '';
      }
    );
  };
}
