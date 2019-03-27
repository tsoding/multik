(* TODO(#72): Picture doesn't have Rotate operation *)
(* TODO: Picture doesn't have Scale operation *)
type t = Nothing
       | Color of Color.t * t
       | Translate of (float * float) * t
       | Rect of float * float
       | Circle of float
       | Text of Font.t * string
       | Compose of t list
       | SizeOf of t * (Rect.t -> t)

let nothing = Nothing

let color (c: Color.t) (p: t): t =
  Color (c, p)

let rect (w: float) (h: float): t =
  Rect (w, h)

let circle (r: float): t =
  Circle r

let compose (ps: t list): t =
  Compose ps

let text (font: Font.t) (text: string): t =
  Text (font, text)

let sizeOf (p: t) (template: Rect.t -> t): t =
  SizeOf (p, template)

let translate (x: float) (y: float) (p: t): t =
  Translate ((x, y), p)
