# Integration Example: Hello World

This example demonstrates how to use `FuckArm64eBootFlags` as a library/tool in another Nix Flake.

## Files
- `example_flake.nix`: A standalone flake that imports this project, builds an `arm64e` C program, and patches it during the derivation build.

## How to Test
1. Save `example_flake.nix` as `flake.nix` in a new directory.
2. Run the build:
   ```bash
   nix build . --impure
   ```
3. Run the resulting patched binary:
   ```bash
   ./result/bin/hello
   ```

## Key Concept
By adding `f4e.overlays.default` to your `pkgs` overlays, the `fuckarm64e` utility becomes available in your `nativeBuildInputs` or `buildInputs`, allowing you to automate architecture conversion as part of your CI/CD or build pipeline.
