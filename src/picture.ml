type picture = Nothing
             | Color of Color.t * picture
             | Rect of int * int * int * int
             | Compose of picture list

let render (p: picture): unit =
  let rec render_with_context (c: Color.t) (p: picture): unit =
    match p with
    | Nothing -> ()
    | Rect (x, y, h, w) ->
       let (r, g, b) = c
       in Console.set_fill_color r g b;
          Console.fill_rect x y h w
    | Compose ps ->
       List.iter (render_with_context c) ps
    | Color (c1, p1) ->
       render_with_context c1 p1
  in render_with_context Color.black p
