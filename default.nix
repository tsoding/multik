with import <nixpkgs> {}; {
    cairoprobeEnv = stdenv.mkDerivation {
        name = "cairoprobe-env";
        buildInputs = [ stdenv
                        gcc
                        gdb
                        gprof
                        ocaml
                        ocamlPackages.findlib
                        ocamlPackages.camlp4
                        pkgconfig
                        cairo
                        SDL2
                        ffmpeg-full
                        ncurses
                      ];
    };
}
