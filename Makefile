MLS=src/flow.ml src/color.ml src/picture.ml src/console.ml src/animation.ml src/multik.ml src/sample.ml src/main.ml
CFLAGS=-Wall -Werror $(shell pkg-config --cflags sdl2 cairo)
LIBS=$(shell pkg-config --libs sdl2 cairo)

multik.opt: src/console_impl.o $(MLS)
	ocamlfind ocamlopt -linkpkg -package threads,dynlink -thread -ccopt "$(CFLAGS)" -I ./src/ -o multik.opt src/console_impl.o $(MLS) -cclib "$(LIBS)"

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
	cp console_impl.o src/

src/sample.cma: src/sample.cmo src/picture.cmo src/color.cmo 
	ocamlc -a -o src/sample.cma src/sample.cmo src/picture.cmo src/color.cmo
