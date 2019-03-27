type t

external make : int -> int -> t = "multik_cairo_make"
external make_from_texture: SdlTexture.t -> t = "multik_cairo_make_from_texture"
external free : t -> unit = "multik_cairo_free"
external set_fill_color : t -> float -> float -> float -> float -> unit = "multik_cairo_set_fill_color"
external fill_rect : t -> float -> float -> float -> float -> unit = "multik_cairo_fill_rect"
external fill_circle : t -> float -> float -> float -> unit = "multik_cairo_fill_circle"
external draw_text : t -> float -> float -> string -> float -> string -> unit = "multik_cairo_draw_text"
external boundary_text: t -> float -> float -> string -> float -> string -> float * float =
  "multik_cairo_boundary_text"
external fill_chess_pattern : t -> unit = "multik_fill_chess_pattern"

let with_context (width, height: int * int) (block: t -> 'a): 'a =
  let context = make width height in
  try
    let value = block context in
    free context;
    value
  with e -> free context;
            raise e

let with_texture (texture: SdlTexture.t) (block: t -> 'a): 'a =
  let context = make_from_texture texture in
  try
    let value = block context in
    free context;
    value
  with e -> free context;
            raise e

let rec boundary (context: t) (p: Picture.t): Rect.t =
  match p with
  | Rect (w, h) -> (0.0, 0.0, w, h)
  | Compose ps ->
     let f (x11, y11, x21, y21) (x12, y12, x22, y22) =
       (min x11 x12, min y11 y12, max x21 x22, max y21 y22)
     in
     let init = (1e120, 1e120, -1e120, -1e120) in
     ps
     |> List.map (boundary context)
     |> List.map Rect.xywh_to_pp
     |> List.fold_left f init
     |> Rect.pp_to_xywh
  | Circle (radius) ->
     (0.0, 0.0, radius *. 2.0, radius *. 2.0)
  | Text (font, text) ->
     let (w, h) = boundary_text context 0.0 0.0 font.name font.size text
     in (0.0, 0.0, w, h)
  | Color (_, p) ->
     boundary context p
  | Nothing -> (0.0, 0.0, 0.0, 0.0)
  | SizeOf (p, template) ->
     p
     |> boundary context
     |> template
     |> boundary context
  | Translate ((x, y), p) ->
     let (x1, y1, w, h) = boundary context p
     in (x +. x1, y +. y1, w, h)

let rec render_with_context (context: t) (c: (float * float) * Color.t) (p: Picture.t): unit =
  let (((x, y) as position), ((r, g, b, a) as color)) = c in
  set_fill_color context r g b a;
  match p with
  | Nothing -> ()
  | Rect (w, h) ->
     fill_rect context x y w h
  | Compose ps ->
     List.iter (render_with_context context c) ps
  | Color (c1, p1) ->
     render_with_context context (position, c1) p1
  | Circle (radius) ->
     fill_circle context x y radius
  | Text (font, text) ->
     draw_text context x y font.name font.size text
  | SizeOf (p, template) ->
      p
      |> boundary context
      |> template
      |> render_with_context context c
  | Translate ((x1, y1), p) ->
     render_with_context context ((x +. x1, y +. y1), color) p

let render (context: t) (p: Picture.t) =
  render_with_context context ((0.0, 0.0), Color.black) p

external save_to_png : t -> string -> unit = "multik_cairo_save_to_png"
