module T = Multik.MakeMultik(
               struct
                 type t = ()
                 let init = ()
                 let render _ = Multik.Nothing
                 let update delta_time s =
                   delta_time |> string_of_float |> print_endline;
                   s
               end)

let () = T.run ()
