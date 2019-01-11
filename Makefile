multik.opt: src/multik.cmx src/anime.cmx src/console.o src/foo.cmx
	ocamlopt -I ./src/ -o multik.opt src/console.o src/foo.cmx src/multik.cmx src/anime.cmx -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/multik.cmx: src/multik.ml src/foo.cmx
	ocamlopt -c -I ./src/ src/multik.ml -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/anime.cmx: src/anime.ml src/multik.cmx
	ocamlopt -c -I ./src/ src/anime.ml -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/foo.cmx: src/foo.ml src/console.o
	ocamlopt -c -I ./src/ src/foo.ml -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/console.o: src/console.c
	ocamlopt -c src/console.c -ccopt "$(shell pkg-config --cflags --libs sdl2)"
	mv console.o src/
