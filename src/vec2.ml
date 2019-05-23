type t = float * float
type homo_t = float * float * float

let as_string (x, y: t): string =
  Printf.sprintf "%f %f\n" x y

let of_ints (x, y : int * int) : t =
  (float_of_int x, float_of_int y)

let of_float (x: float) : t = x, x

let homo (x, y: float * float): homo_t =
  (x, y, 1.0)

let cart (x, y, z: homo_t): t =
  (x /. z, y /. z)

let len ((x, y): t): float =
  sqrt (x *. x +. y *. y)

let norm ((x, y): t): t =
  let n = len (x, y) in
  (x /. n, y /. n)

let (|+|) ((x1, y1): t) ((x2, y2): t) = (x1 +. x2, y1 +. y2)
let (|-|) ((x1, y1): t) ((x2, y2): t) = (x1 -. x2, y1 -. y2)
let (|*|) ((x1, y1): t) ((x2, y2): t) = (x1 *. x2, y1 *. y2)
let (|**|) ((x, y): t) (s: float) = (x *. s, y *. s)
