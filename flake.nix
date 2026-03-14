{
  description = "f4e";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    libebc-src = { url = "github:Guardsquare/LibEBC/1.2"; flake = false; };
  };
  outputs = { self, nixpkgs, libebc-src }:
    let
      l = nixpkgs.lib; s = [ "aarch64-darwin" "x86_64-darwin" ];
    in {
      overlays.default = f: p: {
        fuckarm64e = f.stdenv.mkDerivation {
          name = "f4e"; src = ./.;
          buildPhase = "clang -O3 -o f4e main.c";
          installPhase = "mkdir -p $out/bin; cp f4e $out/bin/";
        };
      };
      packages = l.genAttrs s (system: 
        let pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
        in { inherit (pkgs) fuckarm64e; default = pkgs.fuckarm64e; }
      );
      apps = l.genAttrs s (sys:
        let pkgs = import nixpkgs { system = sys; overlays = [ self.overlays.default ]; }; 
            f = pkgs.fuckarm64e;
        in {
          default = { type = "app"; program = "${pkgs.writeShellScriptBin "f4e" ''
            if [[ "$1" == *.app ]]; then
              B=$(basename "$1" .app); P="''${B}_Patched.app"
              echo "[*] Bundle: $1"; rm -rf "$P"; cp -R "$1" "$P"
              chmod -R +w "$P"; E=$(/usr/bin/defaults read "$(pwd)/$P/Contents/Info" CFBundleExecutable 2>/dev/null || echo "$B")
              BIN="$P/Contents/MacOS/$E"
              if [ -f "$BIN" ]; then 
                ${f}/bin/f4e "$BIN" "$BIN"; codesign -f -s - "$BIN"; echo "[+] Prepared: open $P"
              else echo "[-] Binary not found at $BIN"; exit 1; fi
            else ${f}/bin/f4e "$@"; fi
          ''}/bin/f4e"; };
          test = { type = "app"; program = "${pkgs.writeShellScriptBin "t" ''
            set -e; L="/tmp/f4e.log"; echo "[*] Phase 1: Binary" | tee $L
            echo "int main(){return 0;}" > t.c; clang -arch arm64e t.c -o t_e
            ${f}/bin/f4e t_e t_p >> $L 2>&1; codesign -f -s - t_p
            ./t_p && echo "[+] Success" | tee -a $L
            echo "[*] Phase 2: uname" | tee -a $L
            ${f}/bin/f4e /usr/bin/uname u_p >> $L 2>&1; codesign -f -s - u_p
            ./u_p -a | tee -a $L
            echo "[*] Phase 3: Terminal" | tee -a $L
            rm -rf TerminalPatched.app; cp -R /System/Applications/Utilities/Terminal.app TerminalPatched.app
            chmod -R +w TerminalPatched.app; B="TerminalPatched.app/Contents/MacOS/Terminal"
            ${f}/bin/f4e "$B" "$B" >> $L 2>&1; codesign -f -s - "$B"
            echo "[+] Terminal prepared: open TerminalPatched.app" | tee -a $L
            rm -f t.c t_e t_p u_p
          ''}/bin/t"; };
        }
      );
    };
}
