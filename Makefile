multik.opt: src/multik.cmx src/anime.cmx src/console.o
	ocamlopt -I ./src/ -o multik.opt src/console.o src/multik.cmx src/anime.cmx -ccopt "$(shell pkg-config --cflags --libs sdl2)"

src/multik.cmx: src/multik.ml
	ocamlopt -c -I ./src/ src/multik.ml

src/anime.cmx: src/anime.ml 
	ocamlopt -c -I ./src/ src/anime.ml 

src/console.o: src/console.c
	ocamlopt -c src/console.c -ccopt "$(shell pkg-config --cflags --libs sdl2)"
	mv console.o src/
