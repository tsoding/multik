external init: int -> int -> unit = "console_init"
external free: unit -> unit = "console_free"
external should_quit: unit -> bool = "console_should_quit"
external render: unit -> unit = "console_render"
external set_fill_color: float -> float -> float -> unit = "console_set_fill_color"
external fill_rect: float -> float -> float -> float -> unit = "console_fill_rect"
external fill_circle: float -> float -> float -> unit = "console_fill_circle"
external clear: float -> float -> float -> unit = "console_clear"
external start_cairo_render: unit -> unit = "start_cairo_render"
external stop_cairo_render: unit -> unit = "stop_cairo_render"

let renderPicture (p: Picture.t): unit =
  let rec render_with_context (c: Color.t) (p: Picture.t): unit =
    match p with
    | Nothing -> ()
    | Rect (x, y, w, h) ->
       let (r, g, b) = c
       in set_fill_color r g b;
          fill_rect x y w h
    | Compose ps ->
       List.iter (render_with_context c) ps
    | Color (c1, p1) ->
       render_with_context c1 p1
    | Circle ((x, y), radius) ->
       let (r, g, b) = c
       in set_fill_color r g b;
          fill_circle x y radius
    (* TODO: Picture.Text is not interpreted in Console.renderPicture *)
    | Text ((x, y), _) ->
       let (r, g, b) = c
       in set_fill_color r g b;
          fill_rect x y 200.0 50.0
  in start_cairo_render ();
     clear 0.0 0.0 0.0;
     render_with_context Color.black p;
     stop_cairo_render ()
