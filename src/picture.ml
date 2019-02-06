type t = Nothing
       | Color of Color.t * t
       | Rect of float * float * float * float
       | Circle of (float * float) * float
       | Compose of t list
       | Text of (float * float) * float * string
