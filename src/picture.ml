type picture = Nothing
             | Rect of float * float * float * float
             | Compose of picture list
