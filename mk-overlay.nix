{ inputs, lib }:

final: prev:
let
  # Presumably very expensive?
  cudaPackageSets = lib.pipe prev [
    (lib.filterAttrs (name: _: lib.hasPrefix "cudaPackages" name))
    (builtins.mapAttrs (
      name: oldPs:
      final.callPackage "${inputs.nixpkgs-unstable}/pkgs/top-level/cuda-packages.nix" {
        inherit (oldPs) cudaVersion;
      }
    ))
  ];
in
cudaPackageSets
// lib.optionalAttrs (!(prev ? addDriverRunpath)) { addDriverRunpath = prev.addOpenGLRunpath; }
// lib.optionalAttrs (!(prev.stdenvAdapters ? useLibsFrom)) {
  stdenvAdapters = prev.stdenvAdapters // {
    # Copy-pasted from master, subject to removal...
    useLibsFrom =
      modelStdenv: targetStdenv:
      let
        ccForLibs = modelStdenv.cc;
        cc = final.wrapCCWith {
          cc = targetStdenv.cc.cc;
          useCcForLibs = true;
          gccForLibs = ccForLibs;
        };
      in
      final.overrideCC targetStdenv cc;
  };
}
