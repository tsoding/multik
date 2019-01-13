MLS=src/console.ml src/color.ml src/picture.ml src/multik.ml src/anime.ml
CFLAGS=$(shell pkg-config --cflags --libs sdl2)

multik.opt: src/console_impl.o $(MLS)
	ocamlopt -I ./src/ -o multik.opt src/console_impl.o $(MLS) -ccopt "$(CFLAGS)"

src/console_impl.o: src/console_impl.c
	ocamlopt -c src/console_impl.c -ccopt "$(CFLAGS)"
	mv console_impl.o src/
