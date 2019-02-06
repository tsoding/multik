open Picture

(* TODO(#35): The project mixes up camel case and snake case for function names *)

external init: int -> int -> unit = "console_init"
external free: unit -> unit = "console_free"
external should_quit: unit -> bool = "console_should_quit"
external present: unit -> unit = "console_present"
external set_fill_color: float -> float -> float -> float -> unit = "console_set_fill_color"
external fill_rect: float -> float -> float -> float -> unit = "console_fill_rect"
external fill_circle: float -> float -> float -> unit = "console_fill_circle"
external draw_text: float -> float -> float -> string -> unit = "console_draw_text"
external clear: float -> float -> float -> float -> unit = "console_clear"

external start_cairo_preview: unit -> unit = "start_cairo_preview"
external stop_cairo_preview: unit -> unit = "stop_cairo_preview"

external start_cairo_render: int -> int -> unit = "start_cairo_render"
external stop_cairo_render: string -> unit = "stop_cairo_render"

let rec render_with_context (c: Color.t) (p: Picture.t): unit =
  let (r, g, b, a) = c in
  set_fill_color r g b a;
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
  | Text ((x, y), size, text) ->
     draw_text x y size text

let renderPicture (p: Picture.t): unit =
  start_cairo_preview ();
  clear 0.0 0.0 0.0 0.0;
  render_with_context Color.black p;
  stop_cairo_preview ()

let savePicture (width, height: int * int) (filename: string) (picture: Picture.t) : unit =
  start_cairo_render width height;
  clear 0.0 0.0 0.0 0.0;
  render_with_context Color.black picture;
  stop_cairo_render filename
