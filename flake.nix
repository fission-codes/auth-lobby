{
  description = "fission-codes/auth-lobby";


  # Inputs
  # ======

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
  };


  # Outputs
  # =======

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.simpleFlake {
      inherit self nixpkgs;
      name = "fission-codes/auth-lobby";
      shell = ./nix/shell.nix;
    };
}