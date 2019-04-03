(* TODO(#72): Picture doesn't have Rotate operation *)
(* TODO(#73): Picture doesn't have Scale operation *)
type t = Nothing
       | Color of Color.t * t
       | Translate of (float * float) * t
       | Scale of (float * float) * t
       | Rect of float * float
       | Circle of float
       | Text of Font.t * string
       | Compose of t list
       | SizeOf of t * (Rect.t -> t)

let nothing = Nothing

let color (c: Color.t) (p: t): t =
  Color (c, p)

let rect (w, h: float * float): t =
  Rect (w, h)

let circle (r: float): t =
  Circle r

let compose (ps: t list): t =
  Compose ps

let text (font: Font.t) (text: string): t =
  Text (font, text)

let sizeOf (p: t) (template: Rect.t -> t): t =
  SizeOf (p, template)

let translate (x, y: float * float) (p: t): t =
  Translate ((x, y), p)

let scale (sx, sy: float * float) (p: t): t =
  Scale ((sx, sy), p)
