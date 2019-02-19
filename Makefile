CORE_MLS=src/flow.ml src/color.ml src/picture.ml src/console.ml src/animation.ml
CFLAGS=-Wall -Werror $(shell pkg-config --cflags sdl2 cairo)
LIBS=$(shell pkg-config --libs sdl2 cairo)

all: multik samples/arkanoid.cmo

multik: src/console_impl.o $(CORE_MLS) src/main.ml
	ocamlfind ocamlc -linkpkg -package threads,dynlink -thread \
		-custom -I ./src/ \
		-o multik \
		src/console_impl.o \
		$(CORE_MLS) src/main.ml \
		-ccopt "$(CFLAGS)" \
		-cclib "$(LIBS)" \

src/console_impl.o: src/console_impl.c
	ocamlc -c -ccopt "$(CFLAGS)" src/console_impl.c -cclib "$(LIBS)"
	mv console_impl.o src/

samples/arkanoid.cmo: $(CORE_MLS) samples/arkanoid.ml
	ocamlc -I ./src/ -c $(CORE_MLS) samples/arkanoid.ml
