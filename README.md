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
├── themes/
│   └── team.json          # Shared team theme
├── examples/
│   └── personal-overrides.nix
└── README.md
```

## Customizing

### Themes

Drop `.json` theme files into `themes/` and add them to `teamConfig.themes` in `flake.nix`. Set `settings.theme` to make one the default. Customize colors in `themes/team.json` — see the [Pi theme docs](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/themes.md) for all 51 color tokens.

Teammates can override the theme locally:

```nix
programs.pi.coding-agent.settings.theme = "dark";
```

### Rules

Edit `rules.md` — it's appended to pi's system prompt for every invocation.

### Skills

Add a directory with a `SKILL.md` under `skills/` and reference it in the `teamConfig.skills` list in `flake.nix`.

### Packages (extensions from npm/git)

Pi packages like `pi-lmstudio` are declared in `teamConfig.settings.packages`:

```nix
settings.packages = [
  "npm:pi-lmstudio"
  "npm:@foo/bar@1.0.0"
  "git:github.com/user/repo@v1"
];
```

This writes to `settings.json` and pi auto-installs missing packages on startup — equivalent to running `pi install npm:pi-lmstudio` manually.

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

Build results are cached at [pi.cachix.org](https://pi.cachix.org). Without configuration, Nix won't trust caches declared by a flake, so you'll see:

```
warning: ignoring untrusted flake configuration setting 'extra-substituters'.
```

You can pass `--accept-flake-config` each time, or configure the caches globally so no flag is needed.

### nix-darwin

```nix
# In your nix-darwin configuration:
nix.settings = {
  extra-substituters = [
    "https://pi.cachix.org"
    "https://nix-community.cachix.org"
  ];
  extra-trusted-public-keys = [
    "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
};
```

### NixOS

```nix
# In your NixOS configuration:
nix.settings = {
  extra-substituters = [
    "https://pi.cachix.org"
    "https://nix-community.cachix.org"
  ];
  extra-trusted-public-keys = [
    "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
};
```

### Standalone Nix (no NixOS/nix-darwin)

Add to `~/.config/nix/nix.conf`:

```
extra-substituters = https://pi.cachix.org https://nix-community.cachix.org
extra-trusted-public-keys = pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
```

Once configured, `nix run github:xer0x/pi-setup` just works — no flags, fast downloads from cachix.
