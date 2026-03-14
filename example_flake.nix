{
  description = "Example project using FuckArm64eBootFlags as an input";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Import the FuckArm64eBootFlags flake
    f4e.url = "github:aspauldingcode/FuckArm64eBootFlags";
  };

  outputs = { self, nixpkgs, f4e }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        # Use the exported overlay to add 'fuckarm64e' to our pkgs
        overlays = [ f4e.overlays.default ];
      };
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "hello-patched";
        src = ./.;

        # Use clang to build an arm64e binary, then use f4e to patch it
        buildInputs = [ pkgs.fuckarm64e ];

        buildPhase = ''
          echo '
          #include <stdio.h>
          int main() {
              printf("Hello from a patched arm64e binary!\\n");
              return 0;
          }
          ' > hello.c
          
          # 1. Compile as arm64e
          clang -arch arm64e hello.c -o hello_e
          
          # 2. Patch using the imported utility
          f4e hello_e hello_patched
          
          # 3. Ad-hoc codesign
          codesign -f -s - hello_patched
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp hello_patched $out/bin/hello
        '';
      };

      # Allow running the patched binary directly: nix run . --impure
      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/hello";
      };
    };
}
