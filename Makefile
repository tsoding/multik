CFLAGS=-Wall -Werror -Wconversion $(shell pkg-config --cflags sdl2 cairo)
LIBS=$(shell pkg-config --libs sdl2 cairo)
CORE_MLS=src/flow.ml \
         src/color.ml \
         src/font.ml \
         src/vec2.ml \
         src/rect.ml \
         src/picture.ml \
         src/sdlTexture.ml \
         src/cairo_matrix.ml \
         src/cairo.mli src/cairo.ml \
         src/console.ml \
         src/watcher.ml \
         src/animation.ml \
         src/hotReload.ml
OBJS=src/cairo_matrix_impl.o \
	 src/cairo_impl.o \
	 src/console_impl.o \
	 src/watcher_impl.o
SAMPLES=samples/arkanoid.cmo \
        samples/empty.cmo \
        samples/rotation.cmo \
        samples/swirl.cmo

all: multik $(SAMPLES)

multik: $(OBJS) $(CORE_MLS) src/main.ml Makefile
	ocamlfind ocamlc -pp "camlp4o pa_macro.cmo" -linkpkg -package threads,dynlink -thread \
		-custom -I ./src/ \
		-o multik \
		$(OBJS) \
		$(CORE_MLS) src/main.ml \
		-ccopt "$(CFLAGS)" \
		-cclib "$(LIBS)" \

multik.prof: $(OBJS) $(CORE_MLS) src/main.ml
	ocamlfind ocamlopt -pp "camlp4o pa_macro.cmo -DPROFILE" -linkpkg -package threads,dynlink -thread \
		-I ./src/ \
		-o multik.prof \
		$(OBJS) \
		$(CORE_MLS) src/main.ml \
		-ccopt "-pg -ggdb $(CFLAGS)" \
		-cclib "$(LIBS)" \

src/%.o: src/%.c
	ocamlc -c -ccopt "$(CFLAGS)" $< -cclib "$(LIBS)"
	mv $(notdir $@) src/

samples/%.cmo: samples/%.ml $(CORE_MLS)
	ocamlc -pp "camlp4o pa_macro.cmo" -I ./src/ -c $(CORE_MLS) $<
