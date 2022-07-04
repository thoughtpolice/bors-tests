{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      systems = with flake-utils.lib; [
        system.x86_64-linux
        system.aarch64-linux
        system.x86_64-darwin
        system.aarch64-darwin
      ];

    in flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

      in rec {
        packages = flake-utils.lib.flattenTree rec {
          default = hello;

          hello = pkgs.hello;

          apps = flake-utils.lib.flattenTree rec {
            default = run-vm;
            run-vm = { type = "app"; program = "${packages.hello}/bin/hello"; };
          };
        };
      }
    );
}
