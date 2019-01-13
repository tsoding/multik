type picture = Nothing
             | Color of Color.t * picture
             | Rect of float * float * float * float
             | Compose of picture list

let render (p: picture): unit =
  let render_impl (p: picture) (c: Color.t): unit =
    match p with
    | Nothing -> ()
    | Rect _ -> ()
    | Compose _ -> ()
    | Color _ -> ()
  in render_impl p Color.black
