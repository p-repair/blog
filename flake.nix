{
  description = "Blog of the (p)repair project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshell.flakeModule ];
      systems = [ "x86_64-linux" ];

      perSystem = { inputs', system, ... }:
        let
          pkgs = inputs'.nixpkgs.legacyPackages;
        in
        {
          devshells.default = {
            name = "Blog of the (p)repair project";

            motd = ''

              {202}🔨 Welcome to the blog of the (p)repair project!{reset}
              $(type -p menu &>/dev/null && menu)
            '';

            packages = with pkgs; [
              git
              hugo
            ];
          };
        };
    };
}
