let () =
  (* TODO(#45): animation file path is hardcoded *)
  Dynlink.loadfile("./src/sample.cmo");
  Multik.run ();
  print_endline "done"
