---
name: nix-helper
description: Helps with Nix expressions, flakes, derivations, and NixOS/home-manager modules. Use when the user is working with Nix code or packaging.
---

# Nix Helper

## Usage

When helping with Nix:

1. Prefer flakes over legacy `nix-env` / `nix-shell` when the project already uses flakes
2. Use `nix flake check` and `nix build` to validate changes
3. Reference the Nixpkgs manual for option documentation
4. For home-manager options, check `home-manager option <name>` or the online search

## Common Commands

```bash
# Check a flake
nix flake check

# Build a package
nix build .#packageName

# Enter a dev shell
nix develop

# Search nixpkgs
nix search nixpkgs <query>

# Show flake outputs
nix flake show
```
