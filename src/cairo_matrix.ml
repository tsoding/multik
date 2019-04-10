type t = float * float * float * float * float * float

let as_string (xx, xy, x0, yx, yy, y0: t): string =
  Printf.sprintf "%f %f\n%f %f\n%f %f\n" xx yx xy yy x0 y0

external (|*|): t -> t -> t = "multik_cairo_matrix_product"
external id: unit -> t = "multik_cairo_matrix_id"
external translate: Vec2.t -> t = "multik_cairo_matrix_translate"
external scale: Vec2.t -> t = "multik_cairo_matrix_scale"
external rotate: float -> t = "multik_cairo_matrix_rotate"
external invert: t -> t = "multik_cairo_matrix_invert"
