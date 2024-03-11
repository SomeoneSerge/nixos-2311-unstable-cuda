{
  description = "Use a stable nixpkgs release with the unstable cudaPackages";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        {
          perSystem =
            { lib, system, ... }:
            {
              _module.args.myPkgs = import inputs.nixpkgs {
                inherit system;
                config.cudaSupport = true;
                config.allowUnfreePredicate =
                  p:
                  builtins.all (
                    license:
                    builtins.elem license.shortName [
                      "CUDA EULA"
                      "cuDNN EULA"
                    ]
                  ) (p.meta.licenses or [ p.meta.license ]);
                overlays = [ (import ./mk-overlay.nix { inherit inputs lib; }) ];
              };
            };
        }
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          myPkgs,
          system,
          ...
        }:
        {
          packages.default = myPkgs.cudaPackages.saxpy;
          formatter = inputs.nixpkgs-unstable.legacyPackages.${system}.nixfmt-rfc-style;
        };
      flake = { };
    };
}
