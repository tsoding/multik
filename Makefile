multik.opt: src/multik.cmx src/anime.cmx
	ocamlopt -I ./src/ -o multik.opt src/multik.cmx src/anime.cmx

src/multik.cmx: src/multik.ml
	ocamlopt -c -I ./src/ src/multik.ml

src/anime.cmx: src/anime.ml 
	ocamlopt -c -I ./src/ src/anime.ml 
