module T = Multik.MakeMultik(
               struct
                 (* TODO(#3): Sample animation doesn't render anything substantial *)
                 type t = int
                 let init = 0
                 let render x = Picture.Color
                                  ( Color.red
                                  , Picture.Rect (x, 0, 10, 10)
                                  )
                 let update _ x = x + 1

                 let fps = 30
                 let resolution = (800, 600)
               end)

let () = T.run ()
