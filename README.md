# pi-setup

Shared [Pi](https://pi.dev) (coding agent) configuration for the team, managed with Nix.

Uses [pi.nix](https://github.com/lukasl-dev/pi.nix) for packaging and the home-manager module.

## Quick start

Run pi with team config, no installation needed:

```bash
nix run github:xer0x/pi-setup --accept-flake-config
```

Or from a local checkout:

```bash
nix run . --accept-flake-config
```

## Installation via Home Manager

For a persistent setup, add the flake and import the module:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    pi-setup.url = "github:xer0x/pi-setup";
  };

  outputs = { nixpkgs, home-manager, pi-setup, ... }: {
    homeConfigurations."yourname" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        pi-setup.homeModules.default
        ./home.nix
      ];
    };
  };
}
```

### Override locally

In your personal `home.nix` you can extend or override any team defaults:

```nix
{
  programs.pi.coding-agent = {
    settings.model = "claude-sonnet-4-20250514";
    # environment.ANTHROPIC_API_KEY.file = config.sops.secrets.anthropic.path;
  };
}
```

## How it works

Team configuration is defined once in `flake.nix` (`teamConfig`) and shared two ways:

| Method | How | Best for |
|--------|-----|----------|
| `nix run .` | `lib.mkCodingAgent` wraps pi with config baked in | Quick use, CI, trying it out |
| Home Manager module | Imports pi.nix module + applies team defaults | Persistent dev setup |

Both use the same `teamConfig` attrset, so rules, skills, and settings stay in sync.

## Structure

```
├── flake.nix              # Packages + homeModules (single teamConfig)
├── rules.md               # Shared team rules
├── skills/
│   └── nix-helper/        # Shared skills
│       └── SKILL.md
├── examples/
│   └── personal-overrides.nix
└── README.md
```

## Customizing

### Rules

Edit `rules.md` — it's appended to pi's system prompt for every invocation.

### Skills

Add a directory with a `SKILL.md` under `skills/` and reference it in the `teamConfig.skills` list in `flake.nix`.

### Models

Create a `models.json` and add `models = ./models.json;` to `teamConfig`.

### API Keys

For the home-manager module, use sops-nix:

```nix
programs.pi.coding-agent.environment.ANTHROPIC_API_KEY.file =
  config.sops.secrets.anthropic-api-key.path;
```

For `nix run`, set keys in your shell environment as usual.

## Binary cache

Build results are cached at [pi.cachix.org](https://pi.cachix.org). The flake declares the substituters via `nixConfig` — use `--accept-flake-config` or configure them in your nix settings.
