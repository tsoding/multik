type t = float * float * float * float

let rgba (r: float) (g: float) (b: float) (a: float): t = (r, g, b, a)
let rgb (r: float) (g: float) (b: float): t = rgba r g b 1.0
let black: t = (0.0, 0.0, 0.0, 1.0)
let red: t = (1.0, 0.0, 0.0, 1.0)
let green: t = (0.0, 1.0, 0.0, 1.0)
let blue: t = (0.0, 0.0, 1.0, 1.0)
let white: t = (1.0, 1.0, 1.0, 1.0)
let yellow: t = (1.0, 1.0, 0.0, 1.0)
