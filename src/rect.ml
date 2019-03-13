type t = float * float * float * float

let xywh_to_pp ((x, y, w, h): t): t =
  (x, y, x +. w, y +. h)

let pp_to_xywh ((x1, y1, x2, y2): t): t =
  (x1, y1, x2 -. x1, y2 -. y1)
