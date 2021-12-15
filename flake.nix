{
  description = "Pandoc + LaTeX Writing tools";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};


        latexWithExtraPackages = with pkgs; { extraPackages ? {} }: texlive.combine ({
          inherit (pkgs.texlive) scheme-small
            collection-langgerman
            collection-latexextra
            collection-mathscience
            quattrocento
            tracklang;
          #isodate substr lipsum nonfloat supertabular;
        } // extraPackages);



        pandocWithFilters = with pkgs;
          { name ? "pandoc", filters ? [ ], extraPackages ? [ ], pythonExtra ? (_: [ ]) }:
          let
            pythonDefault = packages: [ packages.ipython packages.pandocfilters packages.pygraphviz ];
            python = python3.withPackages (p: (pythonDefault p) ++ (pythonExtra p));
            pandocPackages = [
              librsvg
            ];
            buildInputs = [ makeWrapper python ] ++ pandocPackages ++ extraPackages;

          in
          runCommand name
            {
              inherit buildInputs;
            } ''
              for file in ${ lib.concatStringsSep " " filters }
              do
                if [[ ! -f "$file" ]] \
                && [[ ! $(PATH="${lib.makeBinPath buildInputs}" type -P "$file") ]]; \
                then (printf "File Not Found or not a File %s" "$file"; exit 1) fi
              done

              makeWrapper ${pkgs.pandoc}/bin/pandoc $out/bin/pandoc \
                ${ lib.concatMapStringsSep " " (filter: "--add-flags \"-F ${filter}\"") filters} \
                --prefix PATH : "${lib.makeBinPath buildInputs}"
            '';

        latex = pkgs.makeOverridable latexWithExtraPackages { };
        pandoc = pkgs.makeOverridable pandocWithFilters { };
      in
      {
        lib = {
          inherit latexWithExtraPackages pandocWithFilters;
        };

        packages = {
          inherit latex pandoc;
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.bashInteractive ];
          buildInputs = [ latex pandocWithFilters ];
        };
      });
}
