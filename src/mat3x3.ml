type t = float * float * float * float * float * float * float * float * float

let as_string (a11, a12, a13, a21, a22, a23, a31, a32, a33: t): string =
  Printf.sprintf "%f %f %f\n%f %f %f\n%f %f %f\n" a11 a12 a13 a21 a22 a23 a31 a32 a33

let (|*|) (a11, a12, a13, a21, a22, a23, a31, a32, a33: t)
      (b11, b12, b13, b21, b22, b23, b31, b32, b33: t): t =
  a11 *. b11 +. a12 *. b21 +. a13 *. b31,
  a11 *. b12 +. a12 *. b22 +. a13 *. b32,
  a11 *. b13 +. a12 *. b23 +. a13 *. b33,
  a21 *. b11 +. a22 *. b21 +. a23 *. b31,
  a21 *. b12 +. a22 *. b22 +. a23 *. b32,
  a21 *. b13 +. a22 *. b23 +. a23 *. b33,
  a31 *. b11 +. a32 *. b21 +. a33 *. b31,
  a31 *. b12 +. a32 *. b22 +. a33 *. b32,
  a31 *. b13 +. a32 *. b23 +. a33 *. b33

let (|*.|) (v1, v2, v3: Vec2.homo_t)
      (a11, a12, a13,
       a21, a22, a23,
       a31, a32, a33: t) =
  v1 *. a11 +. v2 *. a12 +. v3 *. a13,
  v1 *. a21 +. v2 *. a22 +. v3 *. a23,
  v1 *. a31 +. v2 *. a32 +. v3 *. a33

let (|*.*|) (v: Vec2.t) (m: t): Vec2.t =
  Vec2.cart ((Vec2.homo v) |*.| m)

let id = 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0

let translate (x, y: Vec2.t): t =
  1.0, 0.0, x,
  0.0, 1.0, y,
  0.0, 0.0, 1.0

let scale (x, y: Vec2.t): t =
  x  , 0.0, 0.0,
  0.0, y  , 0.0,
  0.0, 0.0, 1.0
