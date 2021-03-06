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

        nix-ccache = import ./src/nix-ccache.nix { inherit pkgs; };

        jobs = rec {
          packages = flake-utils.lib.flattenTree rec {
            hi = nix-ccache.stdenv.mkDerivation {
              name = "hi";
              requiredSystemFeatures = [ "recursive-nix" ];
              separateDebugInfo = true;

              src = ./src/hi.c;
              unpackPhase = ":";

              buildPhase = ''
                gcc -Wall -Og -g -ggdb -o hi.o -c $src -DWHO='"world"'
                gcc -g -ggdb -o hi hi.o
              '';

              installPhase = ''
                mkdir -p $out/bin
                mv hi $out/bin/hi
              '';
            };

            testing = pkgs.runCommand "testing" { } ''
              set -x
              mkdir -p $out/bin $out/share
              ln -s ${packages.hi}/bin/hi $out/bin/testing
              cp ${./dump/hello.txt} $out/share
              cp ${./dump/test.txt} $out/share
              cp ${./dump/wow.txt} $out/share
            '';

            repro-test = pkgs.runCommand "unstable" { } ''
              touch $out
             #echo $RANDOM > $out
            '';
          };

          apps = rec {
            default = testing;
            testing = { type = "app"; program = "${packages.testing}/bin/testing"; };
          };
        };
      in {
        inherit (jobs) apps;
        packages = flake-utils.lib.flattenTree rec {
          default = world;
          world = with pkgs.lib; let
            refs = mapAttrsToList nameValuePair jobs.packages;
            cmds = concatStringsSep "\n" (map (x: ''
              x=$(basename ${x.value})
              echo $x >> $out/nix-refs
              echo ${x.name} >> $out/$x
            '') refs);
          in pkgs.runCommand "world" { } ''
            set -feu; mkdir $out
            ${cmds}
          '';
        } // jobs.packages;
      });
}
