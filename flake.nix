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

      # ── Binary caches (single source of truth for nixConfig + system modules) ──
      caches = {
        substituters = [
          "https://pi.cachix.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      # Daemon-level trust for the caches above. Import into nix-darwin or
      # NixOS so `nix run` no longer warns about untrusted substituters.
      cacheTrustModule = { ... }: {
        nix.settings = {
          substituters = caches.substituters;
          trusted-public-keys = caches.trusted-public-keys;
        };
      };

      # ── Shared team config (used by both `nix run` and the HM module) ──
      #    Note: lean-ctx binary path is injected per-system below
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
            "npm:pi-subagents"
            "npm:pi-lean-ctx"
            "npm:pi-web-access" # websearch, and more
            "npm:@juicesharp/rpiv-ask-user-question"
            "npm:@juicesharp/rpiv-todo"
            "npm:pi-lens" # LSP, Typecheck, tool runners
            "npm:@amaster.ai/pi-memory-mem0"
            "npm:@dietrichgebert/ponytail" # encourages short simple solutions
            # "npm:@foo/bar@1.0.0"
            # "git:github.com/user/repo@v1"
          ];
        };
        # extraArgs = [ "--provider" "anthropic" "--model" "claude-sonnet-4-20250514" ];
      };

      # ── MCP config generator (needs the lean-ctx store path) ──
      mkMcpJson = pkgs: lean-ctx:
        pkgs.writeText "mcp-adapter.json" (builtins.toJSON {
          mcpServers = {
            lean-ctx = {
              command = "${lean-ctx}/bin/lean-ctx";
              lifecycle = "lazy";
              directTools = true;
            };
          };
        });
    in
    {
      # ── lean-ctx binary package ──
      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lean-ctx = pkgs.callPackage ./pkgs/lean-ctx.nix {};
          mcpJson = mkMcpJson pkgs lean-ctx;

          configured = pi.lib.mkCodingAgent {
            inherit pkgs;
            modules = [{
              pi.coding-agent = teamConfig // {
                # Disable pi-lean-ctx's built-in MCP (pi-mcp-adapter owns it)
                environment = {
                  LEAN_CTX_PI_ENABLE_MCP.value = "0";
                };
              };
            }];
          };

          # Wrap the configured pi to also install mcp-adapter.json
          piWrapped = pkgs.writeShellScriptBin "pi" ''
            PI_CODING_AGENT_DIR="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
            mkdir -p "$PI_CODING_AGENT_DIR"

            # Install mcp-adapter.json (merge with existing if present)
            mcp_file="$PI_CODING_AGENT_DIR/mcp-adapter.json"
            if [ ! -f "$mcp_file" ]; then
              cp ${mcpJson} "$mcp_file"
              chmod 0600 "$mcp_file"
            else
              # Merge: existing config wins, we add lean-ctx if missing
              ${pkgs.lib.getExe pkgs.jq} -s '.[0] * .[1]' ${mcpJson} "$mcp_file" > "$mcp_file.tmp"
              mv "$mcp_file.tmp" "$mcp_file"
            fi

            # rpiv-* ship typebox in dependencies; pi warns on every start.
            # Move it to a "*" peer (pi provides typebox anyway).
            # ponytail: drop once juicesharp/rpiv-mono fixes upstream.
            for f in "$PI_CODING_AGENT_DIR"/npm/node_modules/@juicesharp/rpiv-{todo,ask-user-question}/package.json; do
              [ -f "$f" ] || continue
              ${pkgs.lib.getExe pkgs.jq} -e '.dependencies.typebox' "$f" >/dev/null || continue
              ${pkgs.lib.getExe pkgs.jq} 'del(.dependencies.typebox) | .peerDependencies.typebox = "*"' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
            done

            exec ${configured.package}/bin/pi "$@"
          '';
        in {
          default = piWrapped;
          pi = piWrapped;
          lean-ctx = lean-ctx;
        }
      );

      # ── Home-Manager module (import from your HM config) ──
      homeModules.default = { config, lib, pkgs, ... }:
        let
          lean-ctx = pkgs.callPackage ./pkgs/lean-ctx.nix {};
          mcpJson = mkMcpJson pkgs lean-ctx;
        in {
          imports = [ pi.homeModules.default ];

          programs.pi.coding-agent = {
            enable = true;
          } // teamConfig // {
            environment = {
              # Disable pi-lean-ctx's built-in MCP (pi-mcp-adapter owns it)
              LEAN_CTX_PI_ENABLE_MCP.value = "0";
              # ANTHROPIC_API_KEY.file = config.sops.secrets.anthropic-api-key.path;
              # OPENAI_API_KEY.file = config.sops.secrets.openai-api-key.path;
            };
          };

          # Write mcp-adapter.json to Pi's config directory
          home.file.".pi/agent/mcp-adapter.json".source = mcpJson;
        };

      # ── nix-darwin / NixOS modules: trust the team binary caches ──
      #    darwin-configuration: imports = [ pi-setup.darwinModules.default ];
      darwinModules.default = cacheTrustModule;
      nixosModules.default = cacheTrustModule;

      # ── Sanity check ──
      checks = forEachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          build = self.packages.${system}.default;
        }
      );
    };
}
