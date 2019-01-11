multik.opt: src/multik.cmx src/anime.cmx src/console_impl.o src/console.cmx
	ocamlopt -I ./src/ -o multik.opt src/console_impl.o src/console.cmx src/multik.cmx src/anime.cmx -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/multik.cmx: src/multik.ml src/console.cmx
	ocamlopt -c -I ./src/ src/multik.ml -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/anime.cmx: src/anime.ml src/multik.cmx
	ocamlopt -c -I ./src/ src/anime.ml -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/console.cmx: src/console.ml src/console_impl.o
	ocamlopt -c -I ./src/ src/console.ml -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/console_impl.o: src/console_impl.c
	ocamlopt -c src/console_impl.c -ccopt "$(shell pkg-config --cflags --libs sdl2)"
	mv console_impl.o src/
