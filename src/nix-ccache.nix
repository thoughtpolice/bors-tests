{ pkgs }:

let
  outs = rec {
    nix-ccache = pkgs.runCommand "nix-ccache"
      { next = pkgs.stdenv.cc.cc
      ; binutils = pkgs.binutils
      ; nix = pkgs.nix
      ; requiredSystemFeatures = [ "recursive-nix" ]
      ; } ''
        mkdir -p $out/bin
        target=$($next/bin/gcc -v 2>&1 | sed -e 's/^Target: \(.*\)/\1/; t; d')
        version=$($next/bin/gcc -v 2>&1 | sed -e 's/^.*version \([^ ]*\).*/\1/; t; d')
        libexec=$next/libexec/gcc/$target/$version
        if ! [[ -d $libexec ]]; then
          echo "gcc libexec directory '$libexec' does not exist"
          exit 1
        fi
        for i in gcc g++; do
          substitute ${./cc-wrapper.sh} $out/bin/$i \
            --subst-var-by next $next \
            --subst-var-by program $i \
            --subst-var shell \
            --subst-var nix \
            --subst-var system \
            --subst-var out \
            --subst-var binutils \
            --subst-var libexec
          chmod +x $out/bin/$i
        done
        ln -s $next/bin/cpp $out/bin/cpp
      '';

    stdenv = pkgs.overrideCC pkgs.stdenv (pkgs.wrapCC outs.nix-ccache);
  };
in outs
