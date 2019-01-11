module T = Multik.MakeMultik(
               struct
                 (* TODO(#3): Sample animation doesn't render anything substantial *)
                 type t = unit
                 let init = ()
                 let render _ = Multik.Nothing
                 let update delta_time s =
                   delta_time |> string_of_float |> print_endline;
                   s
               end)

let () = T.run ()
