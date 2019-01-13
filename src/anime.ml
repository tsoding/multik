open Picture

module T = Multik.MakeMultik(
               struct
                 (* TODO(#3): Sample animation doesn't render anything substantial *)
                 type t = unit
                 let init = ()
                 let render _ = Nothing
                 let update delta_time s =
                   delta_time |> string_of_float |> print_endline;
                   s

                 let fps = 30
                 let resolution = (1920, 1080)
               end)

let () = T.run ()
