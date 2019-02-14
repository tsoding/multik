MLS=src/flow.ml src/color.ml src/picture.ml src/console.ml src/animation.ml src/multik.ml src/main.ml
CFLAGS=-Wall -Werror $(shell pkg-config --cflags sdl2 cairo)
LIBS=$(shell pkg-config --libs sdl2 cairo)

multik: src/console_impl.o $(MLS)
	ocamlfind ocamlc -linkpkg -package threads,dynlink -thread \
		-custom -I ./src/ \
		-o multik \
		src/console_impl.o \
		$(MLS) \
		-ccopt "$(CFLAGS)" \
		-cclib "$(LIBS)" \

src/console_impl.o: src/console_impl.c
	ocamlc -c -ccopt "$(CFLAGS)" src/console_impl.c -cclib "$(LIBS)"
	mv console_impl.o src/

src/sample.cmo: src/sample.ml
	ocamlc -I ./src/ -c src/color.ml src/picture.ml src/animation.ml src/sample.ml
