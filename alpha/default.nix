{ nixpkgsFunc ?
    # Default for CI reproducibility, optionally override in your configuration.nix.
    import ((import <nixpkgs> {}).pkgs.fetchFromGitHub {
      owner = "NixOS"; repo = "nixpkgs";
      rev = "d757d8142e88187388fbea4e884feadb0e33d36f";
      sha256 = "0lraiidcljgqc16w7nbal1jg0396761iyackw1a6h1v1hjkarhsd";
      #rev = "aebdc892d6aa6834a083fb8b56c43578712b0dab";
      #sha256 = "1bcpjc7f1ff5k7vf5rwwb7g7m4j238hi4ssnx7xqglr7hj4ms0cz";
      #rev = "19879836d10f64a10658d1e2a84fc54b090e2087";
      #sha256 = "1x41ch2mgzs85ivvyp3zqkbh4i0winjg69g5x0p3q7avgrhkl7ph";
    })
}:
let
  stdenv = nixpkgs.stdenv;
  nixpkgs = nixpkgsFunc {
    system = builtins.currentSystem;
    config = {
      packageOverrides = pkgs: {
        nodejs = pkgs."nodejs-6_x";
      };
    };
  };
#  nodejs = nixpkgs."nodejs-4_x";
  rawNodePackages = import ./node {
    pkgs = nixpkgs;
    inherit (nixpkgs) system nodejs;
  };
  nodePackages = rawNodePackages // {
    stencila-node = rawNodePackages.stencila-node.overrideAttrs (oldAttrs: rec {
      buildInputs = (oldAttrs.buildInputs or []) ++ (with nixpkgs; [
        pkgconfig
        cairo
        rawNodePackages.node-pre-gyp
        rawNodePackages.node-gyp-build
      ]);
    });
  };
  stencilla-py = nixpkgs.pythonPackages.buildPythonApplication rec {
    pname = "stencilla-py";
    version = "0.28.0";
    name = "${pname}-${version}";
    meta = {
      homepage = "https://github.com/stencila/py/";
      description = "Stencila for Python";
      license = stdenv.lib.licenses.apsl20;
      maintainers = with stdenv.lib.maintainers; [ nokome ];
    };

    src = nixpkgs.fetchgit {   
      url = "https://github.com/stencila/py";
      rev = "9f3a33aca80100c51fcec6e58f537113b1c5511b";
      sha256 = "0f2jaddvrpkkmf6abnnbybjlwiggjkqg0fi0kwhak2pbx0d3fkrb";
    };

    buildInputs = with nixpkgs.pythonPackages; [
      six
      numpy
      pandas
      matplotlib
      werkzeug
    ];
  };
  buildRPackage = nixpkgs.callPackage <nixpkgs/pkgs/development/r-modules/generic-builder.nix> {
    inherit (nixpkgs.darwin.apple_sdk.frameworks) Cocoa Foundation;
    inherit (nixpkgs) R gettext gfortran;
  };
  pkgdown = buildRPackage rec {
    pname = "pkgdown";
    version = "0.1.0.9000";
    name = "${pname}-${version}";
    meta = {
      homepage = "https://github.com/hadley/pkgdown/";
      description = "Make Static HTML Documentation for a Package";
      license = stdenv.lib.licenses.mit;
      maintainers = with stdenv.lib.maintainers; [ hadley ];
    };

    src = nixpkgs.fetchgit {   
      url = "https://github.com/hadley/pkgdown.git";
      rev = "c8726f9242b2b67f572c16422c83cdc8160c7628";
      sha256 = "08nqxr0334f8z8k3yyyc2sp3jw1znhbqnyypz5qbr95p4c48k1xl";
    };

    buildInputs = with nixpkgs; [
      R
    ] ++ (with rPackages; [
      devtools
      callr
      desc
      digest
      evaluate
      highlight
      httr
      MASS
      magrittr
      memoise
      purrr
      pkgload
      R6
      rematch
      rlang
      rmarkdown
      roxygen2
      tibble
      # tools
      usethis
      whisker
      yaml
      xml2
    ]);
  };
  stencilla-r = stdenv.mkDerivation rec {
    pname = "stencilla-r";
    version = "0.28.0";
    name = "${pname}-${version}";
    meta = {
      homepage = "https://github.com/stencila/r/";
      description = "Stencila for R";
      license = stdenv.lib.licenses.apsl20;
      maintainers = with stdenv.lib.maintainers; [ nokome ];
    };

    src = nixpkgs.fetchgit {   
      url = "https://github.com/stencila/r";
      rev = "c51026b768f29526f9129454bafc5feebd4d48f0";
      sha256 = "1cg6xdsgv2hd2lb20amix4nmz99i7750nb5i83k4137da20kvlyn";
    };

    buildInputs = [
      pkgdown
    ] ++ (with nixpkgs; [
      R
    ] ++ (with rPackages; [
      devtools
      roxygen2
      testthat
      covr
    ]));
  };
  stencilla-alpha = stdenv.mkDerivation {
    name = "stencila-alpha";
    version = "1";
    src = if nixpkgs.lib.inNixShell then null else nixpkgs.nix;

    buildInputs = with nixpkgs; [
      R
      curl
      pkgconfig
      gcc
      gfortran
      jq
      cairo
      nodejs
      python
    ] ++ (with rPackages; [
      devtools

      # core tidyverse
      ggplot2
      dplyr
      tidyr
      readr
      purrr
      tibble

      # Other tideverse
      hms
      stringr
      lubridate
      forcats
      feather
      haven
      httr
      jsonlite
      readxl
      rvest
      xml2
      modelr
      broom
    ]) ++ (with pythonPackages; [
      pip
      ipython
      jupyter
      matplotlib
      numpy
      pandas
      scipy
      sympy
    ]) ++ (with nodePackages; [
      stdlib
      stencila-node
    ]) ++ [
      stencilla-py
      stencilla-r
    ];
  };
in stencilla-alpha

