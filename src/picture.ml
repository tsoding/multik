type t = Nothing
       | Color of Color.t * t
       | Rect of float * float * float * float
       | Circle of (float * float) * float
       | Compose of t list
       | Text of (float * float) * Font.t * string

let nothing = Nothing

let color (c: Color.t) (p: t): t =
  Color (c, p)

let rect (x: float) (y: float) (w: float) (h: float) =
  Rect (x, y, w, h)

let circle (x: float) (y: float) (r: float) =
  Circle ((x, y), r)

let compose (ps: t list) =
  Compose ps

let text (x: float) (y: float) (font: Font.t) (text: string) =
  Text ((x, y), font, text)
