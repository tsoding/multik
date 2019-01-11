with import <nixpkgs> {}; {
    cairoprobeEnv = stdenv.mkDerivation {
        name = "cairoprobe-env";
        buildInputs = [ stdenv
                        gcc
                        ocaml
                        ocamlPackages.findlib
                        pkgconfig
                        cairo
                        SDL2
                        ffmpeg-full
                      ];
    };
}
