{
  description = "Quickshell runtime for Linux Mint";

  inputs = {
    quickshell.url = "git+https://github.com/quickshell-mirror/quickshell?rev=1a4716cde794a59928d9d9fc15f2afc7a95de360";
    nixgl = {
      url = "github:nix-community/nixGL/b6105297e6f0cd041670c3e8628394d4ee247ed5";
      inputs.nixpkgs.follows = "quickshell/nixpkgs";
    };
  };

  outputs = { quickshell, nixgl, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        builtins.listToAttrs (map (system: {
          name = system;
          value = f system;
        }) systems);
    in {
      packages = forAllSystems (system:
        let
          pkgs = quickshell.inputs.nixpkgs.legacyPackages.${system};
          quickshellPackage = quickshell.packages.${system}.default;
          nixglPackage = nixgl.packages.${system}.nixGLIntel;
        in {
          default = pkgs.runCommand "quickshell" {} ''
            mkdir -p "$out/bin"
            cat > "$out/bin/qs" <<'EOF'
            #!${pkgs.runtimeShell}
            exec ${nixglPackage}/bin/nixGLIntel ${quickshellPackage}/bin/qs "$@"
            EOF
            chmod +x "$out/bin/qs"
          '';
        });
    };
}
