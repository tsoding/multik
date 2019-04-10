type t

type transformations_t =
  {
    color: Color.t;
    mat: Mat3x3.t;
  }

let default_transformations =
  {
    color = Color.black;
    mat = Mat3x3.id;
  }

external make : int -> int -> t = "multik_cairo_make"
external make_from_texture: SdlTexture.t -> t = "multik_cairo_make_from_texture"
external free : t -> unit = "multik_cairo_free"
external set_fill_color : t -> Color.t -> unit = "multik_cairo_set_fill_color"
external fill_rect : t -> Rect.t -> unit = "multik_cairo_fill_rect"
external fill_circle : t -> Vec2.t -> float -> unit = "multik_cairo_fill_circle"
external draw_text : t -> Vec2.t -> Font.t -> string -> unit = "multik_cairo_draw_text"
external boundary_text: t -> Vec2.t -> Font.t -> string -> Vec2.t =
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

let rec render_with_context (context: t) (transformations: transformations_t) (p: Picture.t): unit =
  set_fill_color context transformations.color;
  match p with
  | Nothing -> ()
  | Rect (w0, h0) ->
     let open Mat3x3 in
     Rect.from_points ((0.0, 0.0) |*.*| transformations.mat) ((w0, h0) |*.*| transformations.mat)
     |> fill_rect context
  | Compose ps ->
     List.iter (render_with_context context transformations) ps
  | Color (color, p) ->
     render_with_context context ({transformations with color = color}) p
  (* TODO(#81): Circle radius doesn't support scaling *)
  | Circle (radius) ->
     let open Mat3x3 in
     fill_circle context ((0.0, 0.0) |*.*| transformations.mat) radius
  (* TODO(#82): Text does not support scaling *)
  | Text (font, text) ->
     let open Mat3x3 in
     draw_text context ((0.0, 0.0) |*.*| transformations.mat) font text
  | SizeOf (p, template) ->
      p
      |> boundary context
      |> template
      |> render_with_context context transformations
  | Translate (position, p) ->
     let open Mat3x3 in
     render_with_context context {transformations with mat = (transformations.mat) |*| (Mat3x3.translate position)} p
  | Scale (scaling, p) ->
     let open Mat3x3 in
     render_with_context context {transformations with mat = (transformations.mat) |*| (Mat3x3.scale scaling)} p

let render (context: t) (p: Picture.t) =
  render_with_context context default_transformations p

external save_to_png : t -> string -> unit = "multik_cairo_save_to_png"
