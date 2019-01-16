(* TODO(#3): Sample animation doesn't render anything substantial *)
type t =
  {
    position: float * float;
    direction: float * float;
  }

let init =
  {
    position = (50.0, 50.0);
    direction = (50.0, 50.0);
  }

let render state =
  let (x, y) = state.position in
  Picture.Color
    ( Color.red
    , Picture.Circle ((x, y), 50.0)
    )

let update delta_time state =
  let (x, y) = state.position in
  let (dx, dy) = state.direction in
  (* TODO: update should handle wall collisions *)
  { state with position = (x +. dx *. delta_time, y +. dy *. delta_time) }

let fps = 200
let resolution = (800, 600)
