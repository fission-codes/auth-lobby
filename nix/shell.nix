{ pkgs ? import <nixpkgs> {} }: with pkgs; let

  # Dependencies
  # ------------

  deps = {

    tools = [
      curl
      jq
      just
      simple-http-server
      # watchexec
    ];

    languages = [
      elmPackages.elm
      nodejs-18_x
      nodePackages.pnpm
    ];

  };

in

mkShell {

  buildInputs = builtins.concatLists [
    deps.tools
    deps.languages
  ];

}