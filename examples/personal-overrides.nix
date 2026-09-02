{ pkgs, ... }:
{
  # Personal overrides — this file is just an example, not imported by the flake.
  programs.pi.coding-agent = {
    settings.model = "claude-sonnet-4-20250514";

    # If using sops-nix for secrets:
    # environment.ANTHROPIC_API_KEY.file = config.sops.secrets.anthropic-api-key.path;
  };
}
