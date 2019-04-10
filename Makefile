CORE_MLS=src/flow.ml src/color.ml src/font.ml src/vec2.ml src/rect.ml src/picture.ml src/sdlTexture.ml src/mat3x3.ml src/cairo_matrix.ml src/cairo.mli src/cairo.ml src/console.ml src/watcher.ml src/animation.ml
CFLAGS=-Wall -Werror -Wconversion $(shell pkg-config --cflags sdl2 cairo)
LIBS=$(shell pkg-config --libs sdl2 cairo)
OBJS=src/cairo_matrix_impl.o src/cairo_impl.o src/console_impl.o src/watcher_impl.o
SAMPLES=samples/arkanoid.cmo samples/empty.cmo samples/rotation.cmo samples/scalingTest.cmo

all: multik $(SAMPLES)

multik: $(OBJS) $(CORE_MLS) src/main.ml
	ocamlfind ocamlc -linkpkg -package threads,dynlink -thread \
		-custom -I ./src/ \
		-o multik \
		$(OBJS) \
		$(CORE_MLS) src/main.ml \
		-ccopt "$(CFLAGS)" \
		-cclib "$(LIBS)" \

src/console_impl.o: src/console_impl.c
	ocamlc -c -ccopt "$(CFLAGS)" src/console_impl.c -cclib "$(LIBS)"
	mv console_impl.o src/

src/watcher_impl.o: src/watcher_impl.c
	ocamlc -c -ccopt "$(CFLAGS)" src/watcher_impl.c -cclib "$(LIBS)"
	mv watcher_impl.o src/

src/cairo_impl.o: src/cairo_impl.c
	ocamlc -c -ccopt "$(CFLAGS)" src/cairo_impl.c -cclib "$(LIBS)"
	mv cairo_impl.o src/

src/cairo_matrix_impl.o: src/cairo_matrix_impl.c
	ocamlc -c -ccopt "$(CFLAGS)" src/cairo_matrix_impl.c -cclib "$(LIBS)"
	mv cairo_matrix_impl.o src/

samples/%.cmo: samples/%.ml $(CORE_MLS)
	ocamlc -I ./src/ -c $(CORE_MLS) $<
