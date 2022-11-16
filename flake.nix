{
  description = "swaywm development environment";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, flake-compat, ... }:
    let
      inherit (nixpkgs) lib;

      pkgsFor = system:
        import nixpkgs {
          inherit system;
          overlays = [ ];
        };

      targetSystems = [ "aarch64-linux" "x86_64-linux" ];
    in {
      overlays.default = final: prev: {
        swayfx-unwrapped = prev.sway-unwrapped.overrideAttrs
          (old: { src = builtins.path { path = prev.lib.cleanSource ./.; }; });
      };

      packages = nixpkgs.lib.genAttrs targetSystems (system:
        let pkgs = pkgsFor system;
        in (self.overlays.default pkgs pkgs) // {
          default = self.packages.${system}.swayfx-unwrapped;
        });

      devShells = nixpkgs.lib.genAttrs targetSystems (system:
        let pkgs = pkgsFor system;
        in {
          default = pkgs.mkShell {
            name = "swayfx-shell";
            depsBuildBuild = with pkgs; [ pkg-config ];

            nativeBuildInputs = with pkgs; [
              cmake
              meson
              ninja
              pkg-config
              wayland-scanner
              scdoc
            ];

            inputsFrom = [ self.packages.${system}.swayfx-unwrapped ];
          };
        });
    };
}
