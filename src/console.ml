open Picture

external init: int -> int -> unit = "console_init"
external free: unit -> unit = "console_free"
external should_quit: unit -> bool = "console_should_quit"
external present: unit -> unit = "console_present"
external set_fill_color: float -> float -> float -> unit = "console_set_fill_color"
external fill_rect: float -> float -> float -> float -> unit = "console_fill_rect"
external fill_circle: float -> float -> float -> unit = "console_fill_circle"
external draw_text: float -> float -> string -> unit = "console_draw_text"
external clear: float -> float -> float -> unit = "console_clear"
external start_cairo_render: unit -> unit = "start_cairo_render"
external stop_cairo_render: unit -> unit = "stop_cairo_render"

let renderPicture (p: Picture.t): unit =
  let rec render_with_context (c: Color.t) (p: Picture.t): unit =
    let (r, g, b) = c in
    set_fill_color r g b;
    match p with
    | Nothing -> ()
    | Rect (x, y, w, h) ->
       fill_rect x y w h
    | Compose ps ->
       List.iter (render_with_context c) ps
    | Color (c1, p1) ->
       render_with_context c1 p1
    | Circle ((x, y), radius) ->
       fill_circle x y radius
    | Text ((x, y), text) ->
       draw_text x y text
  in start_cairo_render ();
     clear 0.0 0.0 0.0;
     render_with_context Color.black p;
     stop_cairo_render ()

(* TODO(#30): Console.savePicture is not implemented *)
let savePicture (resolution: int * int) (filename: string) (picture: Picture.t) : unit = ()
