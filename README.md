# FuckArm64eBootFlags

A hyper-minimalistic utility to convert Mach-O binaries (including universal FAT binaries) from `arm64e` to `arm64` on macOS.

## Features
- **Smart Bundle Selection**: Patch entire `.app` bundles with a single command.
- **FAT Binary Support**: Automatically handles universal binaries with both `arm64` and `arm64e` slices.
- **Precision Verification**: Built-in PID architecture checking using kernel-level `PROC_PIDARCHINFO`.

## Simple Usage (Nix)

# Open the result
open TerminalPatched.app
```

> [!IMPORTANT]
> **Bundle Requirement**: Patched binaries from a `.app` bundle require their surrounding bundle context (Info.plist, Resources, etc.) to run correctly. Do not copy the patched binary out of its `.app` folder.

### 2. Runtime PID Verification
Check the exact runtime architecture of any running process:
```bash
nix run github:aspauldingcode/FuckArm64eBootFlags -- -p <PID>
```

## Nix Flake Integration (Import as Module)

You can easily use this utility in your own Nix Flake projects. It exports a `default` overlay that provides both the CLI tool and the dylib.

### 1. Add as Input
```nix
inputs.f4e.url = "github:aspauldingcode/FuckArm64eBootFlags";
```

### 2. Use in Outputs
```nix
outputs = { self, nixpkgs, f4e }: {
  # Add to your overlays
  nixpkgs.overlays = [ f4e.overlays.default ];
  
  # Or use a package directly
  my-app = nixpkgs.legacyPackages.aarch64-darwin.stdenv.mkDerivation {
    buildInputs = [ f4e.packages.aarch64-darwin.fuckarm64e ];
  };
};
```

## Advanced Examples

### Manual Binary Patching
```bash
nix run . -- my_arm64e_cli_tool patched_tool
```

### Blacklist Management
```bash
nix run . -- -b PID/ProcessName  # Add to Ammonia blacklist
nix run . -- -u PID/ProcessName  # Remove from blacklist
nix run . -- -l               # List current blacklist
```

## Why `--impure`?
Required for `test` or bundle patching to copy system apps from `/System`.

## Credit/Thanks
- **Alex Spaulding** (@aspauldingcode) - Developer
- [Reductant](https://github.com/SongXiaoXi/Reductant) (by [SongXiaoXi](https://github.com/SongXiaoXi)) - Inspiration. FuckArm64eBootFlags started as a fork of Reductant but quickly became its own thing.
- [libEBC developers](https://www.highcaffeinecontent.com/blog/20190518-Translating-an-ARM-iOS-App-to-Intel-macOS-Using-Bitcode) (Article on translating ARM iOS Apps)
- [libebc ebcutil](https://github.com/Guardsquare/LibEBC) (LibEBC by Guardsquare)

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. This project depends on LibEBC, which is licensed under the Apache License 2.0.

---

**Support the project:**
[☕ Tip Alex on Ko-fi](https://ko-fi.com/aspauldingcode)
