let () =
  Dynlink.loadfile("./src/sample.cmo");
  Multik.run ();
  print_endline "done"
