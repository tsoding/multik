type t = float * float

let (|+|) ((x1, y1): t) ((x2, y2): t) = (x1 +. x2, y1 +. y2)
let (|-|) ((x1, y1): t) ((x2, y2): t) = (x1 -. x2, y1 -. y2)
