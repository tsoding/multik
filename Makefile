MLS=src/flow.ml src/color.ml src/picture.ml src/console.ml src/multik.ml src/sample.ml src/main.ml
CFLAGS=-Wall -Werror $(shell pkg-config --cflags sdl2 cairo)
LIBS=$(shell pkg-config --libs sdl2 cairo)

multik.opt: src/console_impl.o $(MLS)
	ocamlfind ocamlopt -linkpkg -package threads -thread -ccopt "$(CFLAGS)" -I ./src/ -o multik.opt src/console_impl.o $(MLS) -cclib "$(LIBS)"

src/console_impl.o: src/console_impl.c
	ocamlopt -c -ccopt "$(CFLAGS)" src/console_impl.c -cclib "$(LIBS)"
	mv console_impl.o src/
