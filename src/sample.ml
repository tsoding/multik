(* TODO(#3): Sample animation doesn't render anything substantial *)
type t = int
let init = 0
let render x = Picture.Color
                 ( Color.red
                 , Picture.Rect (x, 0, 50, 50)
                 )
let update _ x = x + 1

let fps = 30
let resolution = (800, 600)
