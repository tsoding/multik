type t = float * float * float * float

let xywh_to_pp ((x, y, w, h): t): t =
  (x, y, x +. w, y +. h)

let pp_to_xywh ((x1, y1, x2, y2): t): t =
  (x1, y1, x2 -. x1, y2 -. y1)

let from_points (x1, y1: Vec2.t) (x2, y2: Vec2.t): t =
  (min x1 x2, min y1 y2, abs_float (x2 -. x1), abs_float (y2 -. y1))
