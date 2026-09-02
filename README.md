# pi-setup

Shared [Pi](https://pi.dev) (coding agent) configuration for the team, managed with Nix.

Uses [pi.nix](https://github.com/lukasl-dev/pi.nix) for the home-manager module.

## Usage

Add this flake as an input in your home-manager (or nix-darwin) config:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";

    pi-setup.url = "github:xer0x/pi-setup";   # or your fork
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

That's it — `programs.pi.coding-agent` is enabled with the team defaults.

### Override locally

In your personal `home.nix` you can extend or override:

```nix
{
  programs.pi.coding-agent = {
    settings.model = "claude-sonnet-4-20250514";
    # environment.ANTHROPIC_API_KEY.file = config.sops.secrets.anthropic.path;
  };
}
```

## Structure

```
├── flake.nix              # Exports homeModules.default
├── rules.md               # Shared team rules (injected into Pi)
├── skills/
│   └── nix-helper/        # Shared skills
│       └── SKILL.md
└── README.md
```

## Adding skills

Drop a directory with a `SKILL.md` into `skills/` and add it to the `skills` list in `flake.nix`.

## Adding models

Create a `models.json` and uncomment the `models` line in `flake.nix`. See Pi docs for the format.
