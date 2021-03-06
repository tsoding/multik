type t

external make : int -> int -> t = "multik_cairo_make"
external make_from_texture: SdlTexture.t -> t = "multik_cairo_make_from_texture"
external free : t -> unit = "multik_cairo_free"
external set_fill_color : t -> Color.t -> unit = "multik_cairo_set_fill_color"
external fill_rect : t -> Rect.t -> unit = "multik_cairo_fill_rect"
external fill_circle : t -> Vec2.t -> float -> unit = "multik_cairo_fill_circle"
external draw_text : t -> Vec2.t -> Font.t -> string -> unit = "multik_cairo_draw_text"
external draw_image : t -> string -> unit = "multik_cairo_draw_image"
external boundary_text: t -> Vec2.t -> Font.t -> string -> Vec2.t =
  "multik_cairo_boundary_text"
external boundary_image: string -> Vec2.t =
  "multik_cairo_boundary_image"
external transform : t -> Cairo_matrix.t -> unit = "multik_cairo_transform"

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

(* TODO(#92): Boundary calculcation is probably broken *)
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
     (* TODO(#113): boundary_text should probably have hardcoded position *)
     let (w, h) = boundary_text context (0.0, 0.0) font text
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
  | Scale ((fx, fy), p) ->
     let (x, y, w, h) = boundary context p
     in (fx *. x, fy *. fy, fx *. w, fy *. h)
  | Rotate (_, p) -> boundary context p
  | Image filepath ->
     let (w, h) = boundary_image filepath
     in (0.0, 0.0, w, h)

(* TODO(#110): can we rewrite render_with_context completely in C *)
let rec render_with_context (current_color: Color.t) (context: t) (p: Picture.t): unit =
  match p with
  | Nothing -> ()
  | Rect (w0, h0) ->
     Rect.from_points (0.0, 0.0) (w0, h0)
     |> fill_rect context
  | Compose ps ->
     List.iter (render_with_context current_color context) ps
  | Color (next_color, p) ->
     set_fill_color context next_color;
     render_with_context next_color context p;
     set_fill_color context current_color
  | Circle (radius) ->
     fill_circle context (0.0, 0.0) radius
  | Text (font, text) ->
     draw_text context (0.0, 0.0) font text
  | SizeOf (p, template) ->
      p
      |> boundary context
      |> template
      |> render_with_context current_color context
  | Translate (position, p) ->
     Cairo_matrix.translate position |> transform context;
     render_with_context current_color context p;
     Cairo_matrix.translate position |> Cairo_matrix.invert |> transform context
  | Scale (scaling, p) ->
     Cairo_matrix.scale scaling |> transform context;
     render_with_context current_color context p;
     Cairo_matrix.scale scaling |> Cairo_matrix.invert |> transform context
  | Rotate (angle, p) ->
     Cairo_matrix.rotate angle |> transform context;
     render_with_context current_color context p;
     Cairo_matrix.rotate angle |> Cairo_matrix.invert |> transform context
  | Image filepath ->
     draw_image context filepath

let render (context: t) (p: Picture.t) =
  render_with_context Color.black context p

external save_to_png : t -> string -> unit = "multik_cairo_save_to_png"
