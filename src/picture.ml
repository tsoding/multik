type picture = Nothing
             | Color of Color.t * picture
             | Rect of float * float * float * float
             | Circle of (float * float) * float
             | Compose of picture list

let render (p: picture): unit =
  let rec render_with_context (c: Color.t) (p: picture): unit =
    match p with
    | Nothing -> ()
    | Rect (x, y, w, h) ->
       let (r, g, b) = c
       in Console.set_fill_color r g b;
          Console.fill_rect x y w h
    | Compose ps ->
       List.iter (render_with_context c) ps
    | Color (c1, p1) ->
       render_with_context c1 p1
    | Circle ((x, y), r) ->
       Console.fill_circle x y r
  in Console.start_cairo_render ();
     Console.clear 0.0 0.0 0.0;
     render_with_context Color.black p;
     Console.stop_cairo_render ()
